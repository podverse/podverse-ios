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
    
    var currentAvUrlAsset: AVURLAsset?
    var currentFullDuration = Int64(0)
    var currentHistoryItem: PlayerHistoryItem?
    var currentMetaDataBytes = Int64(0)
    var currentTotalBytes = Int64(0)
    var endBytes = Int64(0)
    var loaderQueue: DispatchQueue
    var mediaData = NSMutableData()
    var response: URLResponse?
    var startBytes = Int64(0)
    
    override init() {
        self.loaderQueue = DispatchQueue(label: "com.Podverse.ResourceLoaderDelegate.loaderQueue")
        super.init()
//        metaPlayer.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions(), context: nil)
    }
    
    func prepareAsset(item: PlayerHistoryItem) {
        
        DispatchQueue.global().async {
            
            self.currentAvUrlAsset = nil
            self.currentFullDuration = 0
            self.currentHistoryItem = item
            self.currentMetaDataBytes = 0
            self.currentTotalBytes = 0
            
            guard let originalUrlString = item.episodeMediaUrl, let originalUrl = URL(string: originalUrlString) else { return }
            
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
            
            guard let remoteFileSize = URL(string: originalUrlString)?.remoteSize else { return }
            self.currentTotalBytes = remoteFileSize
            
            // Since URL.remoteSize is async, make sure the currentAvUrlAsset is still the same
            guard self.currentAvUrlAsset == metaAsset else { return }
            
            // AVAssetResourceLoaderDelegate methods will only be called with a custom (non-http/s) URL protocol scheme AND after an AVPlayerItem is created with that asset and loaded in an AVPlayer.
            if let customUrl = originalUrl.convertToCustomUrl(scheme: "streaming") {
                let asset = AVURLAsset(url: customUrl, options: nil)
                self.currentAvUrlAsset = asset
                
                // TODO: should this be a serial queue? Or is this a serial queue already? How would we pass a serial queue in as the parameter in Swift 3?
                asset.resourceLoader.setDelegate(self, queue: DispatchQueue.global(qos: .background))
                
                let playerItem = AVPlayerItem(asset: asset)
                PVMediaPlayer.shared.avPlayer.replaceCurrentItem(with: playerItem)
            }
            
        }
        
    }
        

        
//        // We need to use the AVAssetResourceLoaderDelegate methhods to calculate and set the byte range request headers, and the AVAssetResourceLoaderDelegate methods will only be called if you provide a custom (non http/https) scheme.
//        
//        guard let originalUrlString = item.episodeMediaUrl, let originalUrl = URL(string: originalUrlString) else { return nil }
//        guard let customUrl = originalUrl.convertToCustomUrl(scheme: "streaming") else { return nil }
//        
//        let asset = AVURLAsset(url: customUrl as URL, options: nil)
//        
//        currentAsset = asset
//        
//        // Once the delegate is set the AVAssetResourceLoaderDelegate shouldWaitForLoadingOfRequestedResource method will begin
//        // TODO: should this be a serial queue? how would we pass a serial queue in as the parameter in Swift 3?
//        asset.resourceLoader.setDelegate(self, queue: DispatchQueue.global(qos: .background))
        
//        return currentAsset
        
//    }
    
    func handleContentInfoRequest(for loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        
        guard let infoRequest = loadingRequest.contentInformationRequest else { return false }
        guard let customMediaUrl = loadingRequest.request.url else { return false }
        guard let originalUrl = customMediaUrl.convertToOriginalUrl() else { return false }
        
        guard loadingRequest.request.url == currentAvUrlAsset?.url else { return false }
        
        if let item = currentHistoryItem {
            
            var request = URLRequest(url: originalUrl)
            
            let startTime = item.startTime
            let startBytes = self.calcByteRangeOffset(metadataBytes: self.currentMetaDataBytes, time: startTime, duration: self.currentFullDuration, fileSize: self.currentTotalBytes)
            
            let endTime = item.endTime
            let endBytes = self.calcByteRangeOffset(metadataBytes: self.currentMetaDataBytes, time: endTime, duration: self.currentFullDuration, fileSize: self.currentTotalBytes)
            
            request.addValue(self.getByteRangeHeaderString(startBytes: startBytes, endBytes: endBytes), forHTTPHeaderField: "Range")
            
            let task = URLSession.shared.downloadTask(with: request) { (tempUrl, response, error) in
                
                self.loaderQueue.async {
                    guard loadingRequest.request.url == self.currentAvUrlAsset?.url else { return }
                    
                    if let response = response, error == nil {
                        infoRequest.update(with: response)
                        loadingRequest.finishLoading()
                    } else {
                        print(error as Any)
                        loadingRequest.finishLoading(with: error)
                    }
                    
                }
                
            }
            
            task.resume()
            
        }
            
        return true
        
    }
    
    func calcByteRangeOffset (metadataBytes: Int64, time: Int64?, duration: Int64, fileSize: Int64) -> Int64 {
        guard duration > Int64(0) else { return Int64(0) }
        
        if let time = time {
            return metadataBytes + Int64((Double(time) / Double(duration)) * Double(fileSize - metadataBytes))
        }
        
        return Int64(0)
    }
    
    func getByteRangeHeaderString(startBytes: Int64, endBytes: Int64) -> String {
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
    
//    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
//        
//        if let player = object as? AVPlayer {
//            
//            // If currentAvUrlAsset does not match the player's AVURLAsset, then a new request must have been made, and we should bail out.
//            guard let observedAsset = player.currentItem?.asset as? AVURLAsset else { return }
//            guard currentAvUrlAsset == observedAsset else { return }
//            
//            if metaPlayer == player && player.currentItem?.status == AVPlayerItemStatus.readyToPlay {
//                currentFullDuration = player.currentItem?.duration
//            } else if avPlayer == player && player.currentItem?.status == AVPlayerItemStatus.readyToPlay {
//                
//            }
//    
//        }
//
//    }

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

