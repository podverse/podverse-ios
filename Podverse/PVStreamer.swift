//
//  PVStreamer
//  Podverse
//
//  Created by Creon on 12/26/16.
//  Copyright © 2016 Podverse LLC. All rights reserved.
//

import UIKit
import AVFoundation
//import MobileCoreServices

class PVStreamer:NSObject, AVAssetResourceLoaderDelegate  {
    static let shared = PVStreamer()
    
    var pendingRequests = [AVAssetResourceLoadingRequest]()
    var urlSession: URLSession = URLSession(configuration: .default)
    
    func streamAudio(item: PlayerHistoryItem) -> AVPlayerItem? {
        self.urlSession.invalidateAndCancel()
        
        guard let mediaUrlString = item.episodeMediaUrl, let mediaUrl = NSURL(string: mediaUrlString) else {
            return nil
        }
        
        guard let remoteFileSize = URL(string: mediaUrlString)?.remoteSize else {
            return nil
        }
        
        // TODO: is this still needed?
        //        guard let calcCustomMediaURL = self.mediaUrlWithCustomScheme(URLString: mediaUrlString, scheme: "http") else {
        //            return
        //        }
        
        // Use the actual URL only for determining the start and end byte range
        let avUrlAsset = AVURLAsset(url: mediaUrl as URL, options: nil)
        
        let duration = Int64(floor(CMTimeGetSeconds(avUrlAsset.duration)))
        
        // If a media file has metadata in the beginning, the clip start time and end time will be off.
        let metadata = avUrlAsset.metadata
        var metadataBytes = Int64(0)
        
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
        
        if let startTime = item.startTime as? Int64 {
            let startBytesRange = calcByteRangeOffset(metadataBytes: metadataBytes, time: startTime, duration: duration, remoteFileSize: remoteFileSize)
        }
        
        if let endTime = item.endTime as? Int64 {
            let endBytesRange = calcByteRangeOffset(metadataBytes: metadataBytes, time: endTime, duration: duration, remoteFileSize: remoteFileSize)
        }
        
        // We need to set a custom scheme in order to override the request header and set the start and end byte ranges
        guard let customSchemeMediaUrl = mediaUrlWithCustomScheme(URLString: mediaUrlString, scheme: "streaming") else {
            return nil
        }
        
        let asset = AVURLAsset(url: mediaUrl as URL, options: nil)
        
        asset.resourceLoader.setDelegate(self, queue: DispatchQueue.main)
        
        return AVPlayerItem(asset: asset)
    }
    
//    var mediaPlayer: AVPlayer?
//    var mediaPlayerItems = [AVPlayerItem]()
//    var isObserving = false

//    var mediaFileData = Data()
//    var response: URLResponse?
//    var urlSession: URLSession = URLSession(configuration: .default)
//    var episodeDuration: Double!
//    var clipStartTimeInSeconds: Double?
//    var clipEndTimeInSeconds: Double?
//    var startBytesRange: Int?
//    var endBytesRange: Int?
//    var metadataBytesOffset = 0
//
//    func processPendingRequests() {
//        var requestsCompleted = [AVAssetResourceLoadingRequest]()
//        for loadingRequest in self.pendingRequests {
//            self.fillInContentInformation(contentInformationRequest: loadingRequest.contentInformationRequest)
//            if let dataRequest = loadingRequest.dataRequest {
//                let didRespondCompletely = self.respondWithDataForRequest(dataRequest: dataRequest)
//                if didRespondCompletely {
//                    requestsCompleted.append(loadingRequest)
//                    loadingRequest.finishLoading()
//                }
//            }
//        }
//        
//        for requestCompleted in requestsCompleted {
//            for (index, pendingRequest) in self.pendingRequests.enumerated() {
//                if requestCompleted == pendingRequest {
//                    self.pendingRequests.remove(at: index)
//                }
//            }
//        }
//    }
//    
//    func fillInContentInformation(contentInformationRequest: AVAssetResourceLoadingContentInformationRequest?) {
//        guard let contentInfoRequest = contentInformationRequest, let response = self.response, let mimeType = response.mimeType else {
//            return
//        }
//        
//        let unmanagedContentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, mimeType as NSString, nil)
//        let cfContentType = unmanagedContentType?.takeRetainedValue()
//        contentInfoRequest.contentType = String(describing: cfContentType)
//        contentInfoRequest.isByteRangeAccessSupported = true
//        contentInfoRequest.contentLength = response.expectedContentLength
//    }
//    
//    // This offset seems to be related to buffering, and is not where we control the offset for the Byte Range Request headers.
//    func respondWithDataForRequest(dataRequest: AVAssetResourceLoadingDataRequest) -> Bool {
//        var startOffset = dataRequest.requestedOffset
//        if dataRequest.currentOffset != 0 {
//            startOffset = dataRequest.currentOffset
//        }
//        
//        let mediaFileDataLength = Int64(self.mediaFileData.count)
//        if mediaFileDataLength < startOffset {
//            return false
//        }
//        
//        let unreadBytes = mediaFileDataLength - startOffset
//        
//        let numberOfBytesToRespondWith: Int64
//        if Int64(dataRequest.requestedLength) > unreadBytes {
//            numberOfBytesToRespondWith = unreadBytes
//        } else {
//            numberOfBytesToRespondWith = Int64(dataRequest.requestedLength)
//        }
//        let range:Range<Int> = Int(startOffset)..<Int(numberOfBytesToRespondWith)
//        dataRequest.respond(with: self.mediaFileData.subdata(in: range))
//        let endOffset = startOffset + Int64(dataRequest.requestedLength)
//        let didRespondFully = mediaFileDataLength >= endOffset
//        return didRespondFully
//    }
//    
//    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
//        guard let interceptedURL = loadingRequest.request.url else {
//            return false
//        }
//        
//        guard let actualURLComponents = NSURLComponents(url: interceptedURL, resolvingAgainstBaseURL: false) else {
//            return false
//        }
//        
//        actualURLComponents.scheme = "http"
//        guard let actualURL = actualURLComponents.url else {
//            return false
//        }
//
//        var request = URLRequest(url: actualURL, cachePolicy: NSURLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 60)
//        request.httpMethod = "GET"
//        let bytesRequestedString = "bytes=" + String(startBytesRange!) + "-" + String(endBytesRange!)
//        request.addValue(bytesRequestedString, forHTTPHeaderField: "Range")
//        self.urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue.main)
//        let task = self.urlSession.dataTask(with: request)
//        task.resume()
//
//        self.pendingRequests.append(loadingRequest)
//        return true
//    }
//    
//    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
//        for (i, pendingRequest) in self.pendingRequests.enumerated() {
//            if pendingRequest == pendingRequests[i] {
//                pendingRequests.remove(at: i)
//            }
//        }
//        pendingRequests = []
//    }
    func calcByteRangeOffset (metadataBytes: Int64, time: Int64, duration: Int64, remoteFileSize: Int64) -> Int64 {
        return metadataBytes + Int64((Double(time) / Double(duration)) * Double(remoteFileSize - metadataBytes))
    }
    
    func mediaUrlWithCustomScheme(URLString: String, scheme: String) -> URL? {
        guard let url = URL(string: URLString), var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }
        components.scheme = scheme
        return components.url
    }
    
}

//extension PVClipStreamer:URLSessionDataDelegate, URLSessionDelegate, URLSessionTaskDelegate {
////    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
////        self.mediaFileData = Data()
////        self.response = response
////        self.processPendingRequests()
////    }
////    
////    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
////        self.mediaFileData.append(data)
////        self.processPendingRequests()
////    }
////    
////    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
////        
////    }
//}
