//
//  PVStreamer
//  Podverse
//
//  Created by Creon on 12/26/16.
//  Copyright © 2016 Podverse LLC. All rights reserved.
//

// Thanks Jared Sinclair for a very excellent demonstration of how to use the ResourceLoaderDelegate!

// ResourceLoaderDelegate Tutorial
// http://blog.jaredsinclair.com/post/149892449150/implementing-avassetresourceloaderdelegate-a

// Sodes Github Project
// https://github.com/jaredsinclair/sodes-audio-example/blob/72548e948d767ba0b3c2894c13b664c843fbd9a6/Sodes/SodesAudio/ResourceLoaderDelegate.swift

import UIKit
import AVFoundation
import MobileCoreServices

class PVStreamer:NSObject {
    static let shared = PVStreamer()
    
    var currentAvUrlAsset: AVURLAsset?
    var currentEndBytes = Int64(0)
    var currentFullDuration = Int64(0)
    var currentHistoryItem: PlayerHistoryItem?
    var currentMetaDataBytes = Int64(0)
    var currentStartBytes = Int64(0)
    var currentTotalBytes = Int64(0)
    var loaderQueue: DispatchQueue
    var mediaData = NSMutableData()
    var pendingRequests = [AVAssetResourceLoadingRequest]()
    var session: URLSession?
    
    override init() {
        self.loaderQueue = DispatchQueue(label: "com.Podverse.ResourceLoaderDelegate.loaderQueue")
        super.init()
    }
    
    func prepareAsset(item: PlayerHistoryItem, streamOnlyRange: Bool = false) -> AVPlayerItem? {
        
        self.session = nil
        self.pendingRequests = []
        self.currentAvUrlAsset = nil
        self.currentEndBytes = 0
        self.currentFullDuration = 0
        self.currentHistoryItem = item
        self.currentMetaDataBytes = 0
        self.currentStartBytes = 0
        self.currentTotalBytes = 0
        
        guard let originalUrlString = item.episodeMediaUrl, let originalUrl = URL(string: originalUrlString) else { return nil }
        
        // The metaAsset is only used to derive the total metadata bytes, and the duration of the full episode if it is not available in the playlistHistoryItem already.
        // TODO: for substantial performance boost, save the full duration of the episode along with the MediaRef as much as possible, because determining the duration from the metaAsset can take a few seconds.
        let metaAsset = AVURLAsset(url: originalUrl as URL, options: nil)
        self.currentAvUrlAsset = metaAsset
        
        // If a media file has metadata in the beginning, the clip start time and end time will be off. Calculate the metadata bytes size to then use it to offset byte range requests.
        self.currentMetaDataBytes = self.getMetadataBytesCount(asset: metaAsset)
        
        // It takes several seconds to retrieve the duration from the asset itself, so use the episodeDuration stored with the playerHistoryItem instead if available.
        if let duration = item.episodeDuration {
            self.currentFullDuration = Int64(duration)
        } else {
            let duration = floor(CMTimeGetSeconds(metaAsset.duration))
            self.currentFullDuration = Int64(duration)
        }
        
        // AVAssetResourceLoaderDelegate methods will only be called with a custom (non-http/s) URL protocol scheme AND after an AVPlayerItem is created with that asset and loaded in an AVPlayer.
        if let customUrl = originalUrl.convertToCustomUrl(scheme: "streaming") {
            let asset = AVURLAsset(url: customUrl, options: nil)
            self.currentAvUrlAsset = asset
            
            // TODO: should this be a serial queue? Or is this a serial queue already? How would we pass a serial queue in as the parameter in Swift 3?
            asset.resourceLoader.setDelegate(self, queue: DispatchQueue.global(qos: .background))
            
            let playerItem = AVPlayerItem(asset: asset)
            
            return playerItem
        }
        
        return nil
        
    }
    
    func processPendingRequests() {
        
        var requestsCompleted = [AVAssetResourceLoadingRequest]()
        
        for loadingRequest in self.pendingRequests {
            if let _ = loadingRequest.contentInformationRequest {
                handleContentInfoRequest(loadingRequest: loadingRequest)
                requestsCompleted.append(loadingRequest)
            } else if let _ = loadingRequest.dataRequest {
                let didRespondCompletely = handleDataRequest(loadingRequest: loadingRequest)
                if didRespondCompletely {
                    requestsCompleted.append(loadingRequest)
                    loadingRequest.finishLoading()
                }
            }
        }
        
        for requestCompleted in requestsCompleted {
            for (i, pendingRequest) in self.pendingRequests.enumerated() {
                if requestCompleted == pendingRequest {
                    self.pendingRequests.remove(at: i)
                }
            }
        }
        
    }
    
    func handleContentInfoRequest (loadingRequest: AVAssetResourceLoadingRequest) {
        
        guard let infoRequest = loadingRequest.contentInformationRequest else { return }
        guard let customMediaUrl = loadingRequest.request.url else { return }
        guard let originalUrl = customMediaUrl.convertToOriginalUrl() else { return }
        
        do {
            var request = try URLRequest(url: originalUrl, method: .get)
            request.addValue("bytes=0-1", forHTTPHeaderField: "Range")
            
            let task = URLSession.shared.downloadTask(with: request) { (tempUrl, response, error) in
                if let response = response as? HTTPURLResponse, error == nil {
                    if let mimeType = response.mimeType, let unmanagedContentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimeType as CFString, nil) {
                        let cfContentType = unmanagedContentType.takeRetainedValue()
                        infoRequest.contentType = String(cfContentType)
                        infoRequest.isByteRangeAccessSupported = true
                        
                        if let contentLengthString = response.allHeaderFields["Content-Range"] as? String, let historyItem = self.currentHistoryItem {
                            let delimiter = "/"
                            let stringComponents = contentLengthString.components(separatedBy: delimiter)
                            if stringComponents.count > 1 {
                                if let contentLength = Int64(stringComponents[1]) {
                                    
                                    self.currentTotalBytes = contentLength
                                    
                                    if let startTime = historyItem.startTime {
                                        self.currentStartBytes = self.calcByteRangeOffset(metadataBytes: self.currentMetaDataBytes, time: startTime, duration: self.currentFullDuration, fileSize: self.currentTotalBytes)
                                    }
                                    
                                    if let endTime = historyItem.endTime {
                                        self.currentEndBytes = self.calcByteRangeOffset(metadataBytes: self.currentMetaDataBytes, time: endTime, duration: self.currentFullDuration, fileSize: self.currentTotalBytes)
                                    }
                                    
                                    var currentPortionBytes = Int64(0)
                                    if self.currentStartBytes < self.currentEndBytes && self.currentEndBytes > 0 {
                                        currentPortionBytes = self.currentEndBytes - self.currentStartBytes
                                    } else {
                                        currentPortionBytes = self.currentTotalBytes - self.currentStartBytes
                                    }
                                    infoRequest.contentLength = currentPortionBytes

                                }
                            }
                        }

                    }
                } else {
                    print(error as Any)
                }
                
                loadingRequest.finishLoading()
            }
            
            task.resume()
            
        } catch {
            print(error.localizedDescription)
        }
        
    }
    
    func handleDataRequest (loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        
        guard let dataRequest = loadingRequest.dataRequest else { return true }
        guard let customMediaUrl = loadingRequest.request.url else { return true }
        guard let originalUrl = customMediaUrl.convertToOriginalUrl() else { return true }
        
        if self.session == nil {
            let config = URLSessionConfiguration.default
            self.session = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue.main)
            
            var request = URLRequest(url: originalUrl, cachePolicy: NSURLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 60)
            
            let byteRangeHeader = generateByteRangeHeaderString(startBytes: self.currentStartBytes, endBytes: self.currentEndBytes)
            request.addValue(byteRangeHeader, forHTTPHeaderField: "Range")
            
            let task = self.session?.dataTask(with: request)
            task?.resume()
            
            return false
        }
        
        var startOffset = dataRequest.requestedOffset
        if dataRequest.currentOffset != 0 {
            startOffset = dataRequest.currentOffset
        }
        
        let mediaFileDataLength = Int64(self.mediaData.length)
        if mediaFileDataLength < startOffset {
            return false
        }
        
        let unreadBytes = mediaFileDataLength - startOffset
        
        let numberOfBytesToRespondWith: Int64
        if Int64(dataRequest.requestedLength) > unreadBytes {
            numberOfBytesToRespondWith = unreadBytes
        } else {
            numberOfBytesToRespondWith = Int64(dataRequest.requestedLength)
        }
        dataRequest.respond(with: self.mediaData.subdata(with: NSMakeRange(Int(startOffset), Int(numberOfBytesToRespondWith))))
                
        let endOffset = startOffset + dataRequest.requestedLength
        let didRespondFully = mediaFileDataLength >= endOffset
        return didRespondFully
    }
    
    func calcByteRangeOffset (metadataBytes: Int64, time: Int64?, duration: Int64, fileSize: Int64) -> Int64 {
        guard duration > Int64(0) else { return Int64(0) }
        
        if let time = time {
            return metadataBytes + Int64((Double(time) / Double(duration)) * Double(fileSize - metadataBytes))
        }
        
        return Int64(0)
    }
    
    func generateByteRangeHeaderString(startBytes: Int64, endBytes: Int64) -> String {
        if (endBytes > startBytes) {
            return "bytes=" + String(startBytes) + "-" + String(endBytes)
        } else {
            return "bytes=" + String(startBytes) + "-"
        }
    }
    
    func getMetadataBytesCount(asset: AVURLAsset) -> Int64 {
        var metadataBytes = Int64(0)
        let metadata = asset.metadata
        
        for item in metadata {            
            // TODO: what's the swiftiest way to do this?
            if let commonKey = item.commonKey, let dataValue = item.dataValue {
                metadataBytes += dataValue.count
            }
        }
        
        return metadataBytes
    }
    
    func checkIfCurrentTimeIsWithinStreamRange(currentTime: Int) -> Bool {
        
        if let item = currentHistoryItem {
            
            var startTime = 0
            if let time = item.startTime {
                startTime = Int(time)
            }
            
            var endTime = 0
            if let time = item.endTime {
                endTime = Int(time)
            }
            
            return currentTime >= startTime && currentTime <= endTime
        }
        
        return false
        
    }
    
}

extension PVStreamer:AVAssetResourceLoaderDelegate {
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        self.pendingRequests.append(loadingRequest)
        processPendingRequests()
        return true
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
        pendingRequests = []
    }
    
}

extension PVStreamer:URLSessionDelegate, URLSessionDataDelegate {
    public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        print(error)
    }
    
//    public func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
//        session.dataTask(with: request).resume()
//    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        self.mediaData = NSMutableData()
        completionHandler(URLSession.ResponseDisposition.allow)
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        self.mediaData.append(data)
        processPendingRequests()
    }
}

