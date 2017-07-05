//
//  PVClipStreamer.swift
//  Podverse
//
//  Created by Creon on 12/26/16.
//  Copyright © 2016 Podverse LLC. All rights reserved.
//

import UIKit
import AVFoundation
import MobileCoreServices

class PVClipStreamer:NSObject, AVAssetResourceLoaderDelegate {
    static let shared = PVClipStreamer()
    
    var mediaPlayer: AVPlayer?
    var mediaPlayerItems = [AVPlayerItem]()
    var isObserving = false
    var pendingRequests = [AVAssetResourceLoadingRequest]()
    var mediaFileData = Data()
    var response: URLResponse?
    var urlSession: URLSession = URLSession(configuration: .default)
    var episodeDuration: Double!
    var clipStartTimeInSeconds: Double?
    var clipEndTimeInSeconds: Double?
    var startBytesRange: Int?
    var endBytesRange: Int?
    var metadataBytesOffset = 0
    
//    func streamClip(clip: Clip) {
//        // Reset the session to nil before streaming a new clip
//        self.urlSession.invalidateAndCancel()
//        
//        guard let mediaUrlString = clip.episode.mediaUrl else {
//            return
//        }
//        
//        // Get remote file total bytes
//        guard let remoteFileSize = URL(string: mediaUrlString)?.remoteSize else {
//            return
//        }
//        
//        guard let calcCustomMediaURL = self.mediaUrlWithCustomScheme(URLString: mediaUrlString, scheme: "http") else {
//            return
//        }
//        
//        let calculateDurationAsset = AVURLAsset(url: calcCustomMediaURL, options: nil)
//        
//        // If an episode.duration is availabe then use it. Else, calculate the episode duration.
//        //        if clip.episode.duration != nil {
//        //            episodeDuration = Double(clip.episode.duration!)
//        //        } else {
//        episodeDuration = CMTimeGetSeconds(calculateDurationAsset.duration)
//        episodeDuration = floor(episodeDuration!)
//        //        }
//        
//        // Since the calculated episodeDuration is sometimes different than the duration of the episode according to its RSS feed (see NPR TED Radio Hour; NPR Fresh Air; NPR etc.), override the episode.duration with the calculated episodeDuration and save
//        //            clip.episode.duration = episodeDuration
//        //            CoreDataHelper.saveCoreData(nil)
//        
//        // NOTE: if a media file has metadata in the beginning, the clip start/end times will be off. The following functions determine the mediadataBytesOffset based on the metadata, and adjusts the start/endByteRanges to include this offset.
//        let metadataList = calculateDurationAsset.metadata
//        var totalMetaDataBytes = 0
//        for item in metadataList {
//            //                print("start over")
//            //                print(item.key)
//            //                print(item.keySpace)
//            //                print(item.commonKey)
//            //                print(item.value)
//            //                print(item.dataValue)
//            //                print(item.extraAttributes)
//            if let dataValue = item.dataValue {
//                totalMetaDataBytes += dataValue.count
//            }
//            if item.commonKey != nil && item.value != nil {
//                //                    if item.commonKey  == "title" {
//                //                        if let dataValue = item.dataValue {
//                //                            totalMetaDataBytes += dataValue.length
//                //                        }
//                //                    }
//                //                    if item.commonKey   == "type" {
//                //                        if let dataValue = item.dataValue {
//                //                            totalMetaDataBytes += dataValue.length
//                //                        }
//                //                    }
//                //                    if item.commonKey  == "albumName" {
//                //                        if let dataValue = item.dataValue {
//                //                            totalMetaDataBytes += dataValue.length
//                //                        }
//                //                    }
//                //                    if item.commonKey   == "artist" {
//                //                        if let dataValue = item.dataValue {
//                //                            totalMetaDataBytes += dataValue.length
//                //                        }
//                //                    }
//                //                    if item.commonKey  == "artwork" {
//                //                        if let dataValue = item.dataValue {
//                //                            totalMetaDataBytes += dataValue.length
//                //                        }
//                //                    }
//            }
//        }
//        metadataBytesOffset = totalMetaDataBytes
//        
//        // TODO: can we refine the startBytesRange and endBytesRange?
//        startBytesRange = metadataBytesOffset + Int((Double(clip.startTime) / episodeDuration) * Double(remoteFileSize - metadataBytesOffset))
//        
//        // If clip has a valid end time, then use it to determine the End Byte Range Request value. Else use the full episode file size as the End Byte Range Request value.
//        if let endTime = clip.endTime {
//            endBytesRange = metadataBytesOffset + Int((Double(endTime) / episodeDuration) * Double(remoteFileSize - metadataBytesOffset))
//        } else {
//            endBytesRange = Int(remoteFileSize)
//        }
//        
//        guard let customSchemeMediaURL = self.mediaUrlWithCustomScheme(URLString: mediaUrlString, scheme: "streaming") else {
//            return
//        }
//        
//        let asset = AVURLAsset(url: customSchemeMediaURL, options: nil)
//        
//        asset.resourceLoader.setDelegate(self, queue: DispatchQueue.main)
//        self.pendingRequests = []
//        
//        let playerItem = AVPlayerItem(asset: asset)
//        PVMediaPlayer.shared.avPlayer = AVPlayer(playerItem: playerItem)
//    }
    
    // In order to override the Request header, we need to set a custom scheme
    func mediaUrlWithCustomScheme(URLString: String, scheme: String) -> URL? {
        guard let url = URL(string: URLString), var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }
        components.scheme = scheme
        return components.url
    }
    
    func processPendingRequests() {
        var requestsCompleted = [AVAssetResourceLoadingRequest]()
        for loadingRequest in self.pendingRequests {
            self.fillInContentInformation(contentInformationRequest: loadingRequest.contentInformationRequest)
            if let dataRequest = loadingRequest.dataRequest {
                let didRespondCompletely = self.respondWithDataForRequest(dataRequest: dataRequest)
                if didRespondCompletely {
                    requestsCompleted.append(loadingRequest)
                    loadingRequest.finishLoading()
                }
            }
        }
        
        for requestCompleted in requestsCompleted {
            for (index, pendingRequest) in self.pendingRequests.enumerated() {
                if requestCompleted == pendingRequest {
                    self.pendingRequests.remove(at: index)
                }
            }
        }
    }
    
    func fillInContentInformation(contentInformationRequest: AVAssetResourceLoadingContentInformationRequest?) {
        guard let contentInfoRequest = contentInformationRequest, let response = self.response, let mimeType = response.mimeType else {
            return
        }
        
        let unmanagedContentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, mimeType as NSString, nil)
        let cfContentType = unmanagedContentType?.takeRetainedValue()
        contentInfoRequest.contentType = String(describing: cfContentType)
        contentInfoRequest.isByteRangeAccessSupported = true
        contentInfoRequest.contentLength = response.expectedContentLength
    }
    
    // This offset seems to be related to buffering, and is not where we control the offset for the Byte Range Request headers.
    func respondWithDataForRequest(dataRequest: AVAssetResourceLoadingDataRequest) -> Bool {
        var startOffset = dataRequest.requestedOffset
        if dataRequest.currentOffset != 0 {
            startOffset = dataRequest.currentOffset
        }
        
        let mediaFileDataLength = Int64(self.mediaFileData.count)
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
        let range:Range<Int> = Int(startOffset)..<Int(numberOfBytesToRespondWith)
        dataRequest.respond(with: self.mediaFileData.subdata(in: range))
        let endOffset = startOffset + dataRequest.requestedLength
        let didRespondFully = mediaFileDataLength >= endOffset
        return didRespondFully
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        guard let interceptedURL = loadingRequest.request.url else {
            return false
        }
        
        guard let actualURLComponents = NSURLComponents(url: interceptedURL, resolvingAgainstBaseURL: false) else {
            return false
        }
        
        actualURLComponents.scheme = "http"
        guard let actualURL = actualURLComponents.url else {
            return false
        }

        var request = URLRequest(url: actualURL, cachePolicy: NSURLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 60)
        request.httpMethod = "GET"
        let bytesRequestedString = "bytes=" + String(startBytesRange!) + "-" + String(endBytesRange!)
        request.addValue(bytesRequestedString, forHTTPHeaderField: "Range")
        self.urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue.main)
        let task = self.urlSession.dataTask(with: request)
        task.resume()

        self.pendingRequests.append(loadingRequest)
        return true
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
        for (i, pendingRequest) in self.pendingRequests.enumerated() {
            if pendingRequest == pendingRequests[i] {
                pendingRequests.remove(at: i)
            }
        }
        pendingRequests = []
    }
}

extension PVClipStreamer:URLSessionDataDelegate, URLSessionDelegate, URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        self.mediaFileData = Data()
        self.response = response
        self.processPendingRequests()
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        self.mediaFileData.append(data)
        self.processPendingRequests()
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        
    }
}
