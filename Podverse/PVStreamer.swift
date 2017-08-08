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
    
    let avPlayer = PVMediaPlayer.shared.avPlayer
    
    var currentAsset: AVURLAsset?
    var currentFullDuration: CMTime?
    var currentRequest: URLRequest?
    var endBytes = Int64(0)
    var loaderQueue: DispatchQueue
    var mediaData = NSMutableData()
    var playerHistoryItem: PlayerHistoryItem?
    var response: URLResponse?
    var startBytes = Int64(0)
    
    override init() {
        self.loaderQueue = DispatchQueue(label: "com.Podverse.ResourceLoaderDelegate.loaderQueue")
        super.init()
        avPlayer.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions(), context: nil)
    }
    
    func prepareAsset(item: PlayerHistoryItem) -> AVURLAsset? {
        
        // We need to use the AVAssetResourceLoaderDelegate methhods to calculate and set the byte range request headers, and the AVAssetResourceLoaderDelegate methods will only be called if you provide a custom (non http/https) scheme.
        
        guard let originalUrlString = item.episodeMediaUrl, let originalUrl = URL(string: originalUrlString) else { return nil }
        guard let customUrl = originalUrl.convertToCustomUrl(scheme: "streaming") else { return nil }
        
        let asset = AVURLAsset(url: customUrl as URL, options: nil)
        
        // TODO: is there a better way to do this? without setting currentAsset and playerHistoryItem on parent scope?
        currentAsset = asset
        playerHistoryItem = item
        
        // Once the delegate is set the AVAssetResourceLoaderDelegate shouldWaitForLoadingOfRequestedResource method will begin
        // TODO: should this be a serial queue? how would we pass a serial queue in as the parameter in Swift 3?
        asset.resourceLoader.setDelegate(self, queue: DispatchQueue.global(qos: .background))
        
        return asset
        
    }
    
    func handleContentInfoRequest(for loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        
        guard let infoRequest = loadingRequest.contentInformationRequest else { return false }
        guard let customMediaUrl = loadingRequest.request.url else { return false }
        guard let originalUrl = customMediaUrl.convertToOriginalUrl() else { return false }
        
        if let asset = currentAsset, let item = playerHistoryItem {
            
            let mediaUrl = asset.url
            
            // If a media file has metadata in the beginning, the clip start time and end time will be off. Calculate the metadata bytes size to then use it to offset byte range requests.
            let metadataBytes = getMetadataBytesCount(asset: asset)
            
            currentFullDuration = asset.duration
            
            if let duration = currentFullDuration {
                
                let durationInt64 = Int64(CMTimeGetSeconds(duration))
                
                var request = URLRequest(url: originalUrl)
                
                let task = URLSession.shared.downloadTask(with: request) { (tempUrl, response, error) in
                    
                    // TODO: should this really be put in loaderQueue async?
                    self.loaderQueue.async {
                        if let response = response, error == nil {
                            
                            let expectedContentLength = response.expectedContentLength
                            
                            if let startTime = item.startTime {
                                self.startBytes = self.calcByteRangeOffset(metadataBytes: metadataBytes, time: startTime, duration: durationInt64, expectedContentLength: expectedContentLength)
                            }
                            
                            if let endTime = item.endTime {
                                self.endBytes = self.calcByteRangeOffset(metadataBytes: metadataBytes, time: endTime, duration: durationInt64, expectedContentLength: expectedContentLength)
                            }
                            
                            if let dataRequest = loadingRequest.dataRequest {
                                request.addValue(self.getByteRangeHeaderString(startBytes: self.startBytes, endBytes: self.endBytes), forHTTPHeaderField: "Range")
                            }
//        
//                            Bail early if the content info request was cancelled
//                            guard !loadingRequest.isCancelled else { return }
//        
//                            TODO: do we need something like this?
//                            guard let request = self.currentRequest as? ContentInfoRequest,
//                                loadingRequest === request.loadingRequest else
//                            {
//                                SodesLog("Bailing early because the loading request has changed.")
//                                return
//                            }
//        
                            infoRequest.update(with: response)
                            loadingRequest.finishLoading()
                            
                        } else {
                            print(error)
                        }
                        
                    }
                    
                }
                
                task.resume()
                
            }
            
        }
        
        return true
        
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let newValue = change?[.newKey]
    }
    
    func calcByteRangeOffset (metadataBytes: Int64, time: Int64, duration: Int64, expectedContentLength: Int64) -> Int64 {
        return metadataBytes + Int64((Double(time) / Double(duration)) * Double(expectedContentLength - metadataBytes))
    }
        
    func getByteRangeHeaderString(startBytes: Int64, endBytes: Int64) -> String {
        return "bytes=" + String(startBytes) + "-" + String(endBytes)
    }
    
    func getMetadataBytesCount(asset: AVURLAsset) -> Int64 {
        var metadataBytes = Int64(0)
        let metadata = asset.metadata
        
        for item in metadata {
            if let dataValue = item.dataValue {
                metadataBytes += dataValue.count
            }
            
            // TODO: what's the swiftiest way to do this?
            if let commonKey = item.commonKey, let dataValue = item.dataValue {
                if commonKey == "title" || commonKey == "type" || commonKey == "albumName" ||  commonKey == "artist" || commonKey == "artwork" {
                    metadataBytes += dataValue.count
                }
            }
        }
        
        return metadataBytes
    }
    
}

extension PVStreamer:AVAssetResourceLoaderDelegate {
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        
        if let _ = loadingRequest.contentInformationRequest {
            return handleContentInfoRequest(for: loadingRequest)
        } else if let _ = loadingRequest.dataRequest {
//             return handleDataRequest(for: loadingRequest)
            return false
        } else {
            return false
        }
        
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
        print("huh")
    }
    
}

//extension PVStreamer:URLSessionDataDelegate {
//    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
//        print(error)
//    }
//    
//    public func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
//        URLSession.shared.dataTask(with: request).resume()
//    }
//    
//    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
//        remoteFileSize = response.expectedContentLength
//        session.invalidateAndCancel()
//    }
//}

