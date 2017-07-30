//
//  PVStreamer
//  Podverse
//
//  Created by Creon on 12/26/16.
//  Copyright © 2016 Podverse LLC. All rights reserved.
//

import UIKit
import AVFoundation
import MobileCoreServices

class PVStreamer:NSObject {
    static let shared = PVStreamer()
    
    let avPlayer = PVMediaPlayer.shared.avPlayer
    
    let metaAVPlayer = AVPlayer()
    var metaSession: URLSession!
    
    var mediaData = NSMutableData()
    var response: URLResponse?
    var startBytes = Int64(0)
    var endBytes = Int64(0)
    var remoteFileSize: Int64?
    
    var playerHistoryItem: PlayerHistoryItem?
    
    override init() {
        super.init()
        metaAVPlayer.addObserver(self, forKeyPath: "status", options: [.old, .new], context: nil)
        
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.urlCache = nil
        self.metaSession = URLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: OperationQueue())
    }
    
    deinit {
        metaAVPlayer.removeObserver(self, forKeyPath: "status")
    }
    
    func streamAudio(item: PlayerHistoryItem) {
        
        guard let mediaUrlString = item.episodeMediaUrl, let mediaUrl = URL(string: mediaUrlString) else {
            return
        }
        
        metaAVPlayer.replaceCurrentItem(with: nil)
        
        //  We can only determine the episode duration after an AVPlayerItem is playable, and we need to know the episode duration to know exactly what byte range request headers we want to use for the clip.
        // NOTE: after the AVPlayerItem is initialized, the observeValue override will fire when the AVPlayerItem is playable, and then the makeByteRangeRequest method will be called.
        let avUrlAsset = AVURLAsset(url: mediaUrl, options: nil)
        let avPlayerItem = AVPlayerItem(asset: avUrlAsset)
        metaAVPlayer.replaceCurrentItem(with: avPlayerItem)
        
        // Set playerHistoryItem on the parent scope so it is available in the makeByteRangeRequest function
        playerHistoryItem = item
        
    }
    
    func makeByteRangeRequest() {
        
        // If a media file has metadata in the beginning, the clip start time and end time will be off.
        var metadataBytes = Int64(0)
        if let metadata = metaAVPlayer.currentItem?.asset.metadata {
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
        }
        
        if let duration = metaAVPlayer.currentItem?.asset.duration, let item = playerHistoryItem {
            
            guard let mediaUrlString = item.episodeMediaUrl, let mediaUrl = URL(string: mediaUrlString) else {
                return
            }
            
            let durationInt64 = Int64(CMTimeGetSeconds(duration))
            
            DispatchQueue.global().async {

                mediaUrl.remoteSize()
                
                if let remoteFileSize = self.remoteFileSize {
                    if let startTime = item.startTime {
                        self.startBytes = self.calcByteRangeOffset(metadataBytes: metadataBytes, time: startTime, duration: durationInt64, remoteFileSize: remoteFileSize)
                    }
    
                    if let endTime = item.endTime {
                        self.endBytes = self.calcByteRangeOffset(metadataBytes: metadataBytes, time: endTime, duration: durationInt64, remoteFileSize: remoteFileSize)
                    }
                    
                    // We must set a custom scheme in order for the AVAssetResourceLoaderDelegate to be able to override the request header and set the start and end byte ranges
                    guard let customSchemeMediaUrl = self.mediaUrlWithCustomScheme(urlString: mediaUrlString, scheme: "streaming") else {
                        return
                    }
                    
                    let asset = AVURLAsset(url: customSchemeMediaUrl as URL, options: nil)
                    
                    // With the delegate set, the AVAssetResourceLoaderDelegate shouldWaitForLoadingOfRequestedResource method will handle setting the byte range request header before making the request.
                    asset.resourceLoader.setDelegate(self, queue: DispatchQueue.main)
                    
                    self.avPlayer.replaceCurrentItem(with: AVPlayerItem(asset: asset))
                }
                
            }
            
        }
        
    }
    
    func calcByteRangeOffset (metadataBytes: Int64, time: Int64, duration: Int64, remoteFileSize: Int64) -> Int64 {
        return metadataBytes + Int64((Double(time) / Double(duration)) * Double(remoteFileSize - metadataBytes))
    }
    
    func mediaUrlWithCustomScheme(urlString: String, scheme: String) -> URL? {
        guard let url = URL(string: urlString), var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }
        
        if urlString.hasPrefix("http://") {
            components.scheme = "http" + scheme
        } else {
            components.scheme = "https" + scheme
        }

        return components.url
    }
    
    func getActualUrl(url: URL) -> URL? {
        let actualUrlComponents = NSURLComponents(url: url, resolvingAgainstBaseURL: false)
        if url.scheme == "httpstreaming" {
            actualUrlComponents?.scheme = "http"
        } else if url.scheme == "httpsstreaming" {
            actualUrlComponents?.scheme = "https"
        }
        return actualUrlComponents?.url
    }
    
    func getByteRangeHeaderString(startBytes: Int64, endBytes: Int64) -> String {
        return "bytes=" + String(startBytes) + "-" + String(endBytes)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if keyPath == #keyPath(AVPlayerItem.status) {
            let status: AVPlayerItemStatus
            
            // Get the status change from the change dictionary
            if let statusNumber = change?[.newKey] as? NSNumber {
                status = AVPlayerItemStatus(rawValue: statusNumber.intValue)!
            } else {
                status = .unknown
            }
            
            // Switch over the status
            switch status {
            case .readyToPlay:
                makeByteRangeRequest()
                break
            case .failed:
                break
            case .unknown:
                break
            }
            
            metaAVPlayer.replaceCurrentItem(with: nil)
        }
    }
    
}

extension PVStreamer:URLSessionDataDelegate {
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        print(error)
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        print("ok1")
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didBecome streamTask: URLSessionStreamTask) {
        print("ok2")
    }
    
    @available(iOS 10.0, *)
    public func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        print("ok3")
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        
        if let task = self.metaSession?.dataTask(with: request) {
            task.resume()
        }
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        remoteFileSize = response.expectedContentLength
        session.invalidateAndCancel()
    }
}


extension PVStreamer:AVAssetResourceLoaderDelegate {
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        
        if let interceptedUrl = loadingRequest.request.url, let actualUrl = getActualUrl(url: interceptedUrl) {
            
            let urlString = actualUrl.absoluteString
            let session = URLSession.shared
            
            if let infoRequest = loadingRequest.contentInformationRequest {
                infoRequest.isByteRangeAccessSupported = true
                infoRequest.contentLength = endBytes - startBytes
            }

        }
        
        return true
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
        print("huh")
    }
    
}
