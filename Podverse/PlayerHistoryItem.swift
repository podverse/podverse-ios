//
//  PlayerHistoryItem.swift
//  Podverse
//
//  Created by Mitchell Downey on 5/21/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

import UIKit

extension Notification.Name {
    static let clipUpdated = Notification.Name("clipUpdated")
}

class PlayerHistoryItem: NSObject, NSCoding {
    
    var mediaRefId:String?
    let podcastId:String?
    let podcastFeedUrl:String?
    let podcastTitle:String?
    let podcastImageUrl:String?
    let episodeDuration:Int64?
    let episodeId:String?
    let episodeImageUrl:String?
    let episodeMediaUrl:String?
    let episodePubDate:Date?
    let episodeSummary:String?
    let episodeTitle:String?
    var startTime:Int64?     // If startTime and endTime = 0, then item is a clip, else it is an episode
    var endTime:Int64?
    var clipTitle:String?
    var ownerName:String?
    var ownerId:String?
    var hasReachedEnd:Bool?
    var lastPlaybackPosition:Int64?
    var lastUpdated:Date?
    var isPublic:Bool?
    
    required init(mediaRefId:String? = nil, podcastId:String?, podcastFeedUrl:String? = nil, podcastTitle:String? = nil, podcastImageUrl:String? = nil, episodeDuration: Int64? = nil, episodeId:String? = nil, episodeMediaUrl:String? = nil, episodeTitle:String? = nil, episodeImageUrl:String? = nil, episodeSummary:String? = nil, episodePubDate:Date? = nil, startTime:Int64? = nil, endTime:Int64? = nil, clipTitle:String? = nil, ownerName:String? = nil, ownerId:String? = nil, hasReachedEnd:Bool, lastPlaybackPosition:Int64? = 0, lastUpdated:Date? = nil, isPublic:Bool? = false) {
        self.mediaRefId = mediaRefId
        self.podcastId = podcastId
        self.podcastFeedUrl = podcastFeedUrl
        self.podcastTitle = podcastTitle
        self.podcastImageUrl = podcastImageUrl
        self.episodeDuration = episodeDuration
        self.episodeId = episodeId
        self.episodeMediaUrl = episodeMediaUrl
        self.episodeImageUrl = episodeImageUrl
        self.episodePubDate = episodePubDate
        self.episodeSummary = episodeSummary
        self.episodeTitle = episodeTitle
        self.startTime = startTime
        self.endTime = endTime
        self.clipTitle = clipTitle
        self.ownerName = ownerName
        self.ownerId = ownerId
        self.hasReachedEnd = hasReachedEnd
        self.lastPlaybackPosition = lastPlaybackPosition
        self.lastUpdated = lastUpdated
        self.isPublic = isPublic
    }
    
    required init(coder decoder: NSCoder) {
        self.mediaRefId = decoder.decodeObject(forKey: "mediaRefId") as? String
        self.podcastId = decoder.decodeObject(forKey: "podcastId") as? String
        self.podcastFeedUrl = decoder.decodeObject(forKey: "podcastFeedUrl") as? String
        self.podcastTitle = decoder.decodeObject(forKey: "podcastTitle") as? String
        self.podcastImageUrl = decoder.decodeObject(forKey: "podcastImageUrl") as? String
        self.episodeDuration = decoder.decodeObject(forKey: "episodeDuration") as? Int64
        self.episodeId = decoder.decodeObject(forKey: "episodeId") as? String
        self.episodeImageUrl = decoder.decodeObject(forKey: "episodeImageUrl") as? String
        self.episodeMediaUrl = decoder.decodeObject(forKey: "episodeMediaUrl") as? String
        self.episodeSummary = decoder.decodeObject(forKey: "episodeSummary") as? String
        self.episodePubDate = decoder.decodeObject(forKey: "episodePubDate") as? Date
        self.episodeTitle = decoder.decodeObject(forKey: "episodeTitle") as? String
        self.startTime = decoder.decodeObject(forKey: "startTime") as? Int64 ?? 0
        self.endTime = decoder.decodeObject(forKey: "endTime") as? Int64
        self.clipTitle = decoder.decodeObject(forKey: "clipTitle") as? String
        self.ownerName = decoder.decodeObject(forKey: "ownerName") as? String
        self.ownerId = decoder.decodeObject(forKey: "ownerId") as? String
        self.hasReachedEnd = decoder.decodeObject(forKey: "hasReachedEnd") as? Bool
        self.lastPlaybackPosition = decoder.decodeObject(forKey: "lastPlaybackPosition") as? Int64
        self.lastUpdated = decoder.decodeObject(forKey: "lastUpdated") as? Date
        self.isPublic = decoder.decodeObject(forKey: "isPublic") as? Bool
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(mediaRefId, forKey: "mediaRefId")
        coder.encode(podcastId, forKey: "podcastId")
        coder.encode(podcastFeedUrl, forKey:"podcastFeedUrl")
        coder.encode(podcastTitle, forKey:"podcastTitle")
        coder.encode(podcastImageUrl, forKey:"podcastImageUrl")
        coder.encode(episodeDuration, forKey:"episodeDuration")
        coder.encode(episodeId, forKey:"episodeId")
        coder.encode(episodeImageUrl, forKey:"episodeImageUrl")
        coder.encode(episodeMediaUrl, forKey:"episodeMediaUrl")
        coder.encode(episodePubDate, forKey:"episodePubDate")
        coder.encode(episodeSummary, forKey:"episodeSummary")
        coder.encode(episodeTitle, forKey:"episodeTitle")
        coder.encode(startTime, forKey:"startTime")
        coder.encode(endTime, forKey:"endTime")
        coder.encode(clipTitle, forKey:"clipTitle")
        coder.encode(ownerName, forKey:"ownerName")
        coder.encode(ownerId, forKey:"ownerId")
        coder.encode(hasReachedEnd, forKey:"hasReachedEnd")
        coder.encode(lastPlaybackPosition, forKey:"lastPlaybackPosition")
        coder.encode(lastUpdated, forKey:"lastUpdated")
        coder.encode(isPublic, forKey:"isPublic")
    }
    
    func isClip() -> Bool {
        
        if let startTime = self.startTime {
            if startTime > 0 {
                return true
            }
        } else if let endTime = self.endTime {
            if endTime > 0 {
                return true
            }
        }
        
        return false
    }
    
    func convertClipToEpisode() -> PlayerHistoryItem {
        self.clipTitle = nil
        self.startTime = 0
        self.endTime = nil
        self.ownerName = nil
        self.ownerId = nil
        self.hasReachedEnd = false
        self.lastPlaybackPosition = nil
        self.lastUpdated = nil
        
        return self
    }
    
    func readableStartAndEndTime() -> String? {
        var time: String?
        
        if let startTime = self.startTime {
            if let endTime = self.endTime {
                if endTime > 0 {
                    time = startTime.toMediaPlayerString() + " to " + endTime.toMediaPlayerString()
                }
            } else if startTime == 0 {
                time = "--:--"
            } else {
                time = startTime.toMediaPlayerString() + " to " + "..."
            }
        }
        
        return time
    }
    
    func convertToMediaRefPostString(shouldSaveFullEpisode: Bool = false) -> [String: Any] {
        
        var values: [String: Any] = [:]
        
        if shouldSaveFullEpisode {
            if let episodeMediaUrl = self.episodeMediaUrl {
                values["mediaRefId"] = "episode_" + episodeMediaUrl
            }
        } else {
            if let mediaRefId = self.mediaRefId {
                values["mediaRefId"] = mediaRefId
            }
        }
        
        if let podcastId = self.podcastId {
            values["podcastId"] = podcastId
        }
        
        if let podcastFeedUrl = self.podcastFeedUrl {
            values["podcastFeedUrl"] = podcastFeedUrl
        }
        
        if let podcastTitle = self.podcastTitle {
            values["podcastTitle"] = podcastTitle
        }
        
        if let podcastImageUrl = self.podcastImageUrl {
            values["podcastImageUrl"] = podcastImageUrl
        }

        if let episodeDuration = self.episodeDuration {
            values["episodeDuration"] = String(episodeDuration)
        }
        
        if let episodeId = self.episodeId {
            values["episodeId"] = episodeId
        }

        if let episodeImageUrl = self.episodeImageUrl {
            values["episodeImageUrl"] = episodeImageUrl
        }
        
        if let episodeMediaUrl = self.episodeMediaUrl {
            values["episodeMediaUrl"] = episodeMediaUrl
        }
        
        if let episodePubDate = self.episodePubDate {
            values["episodePubDate"] = episodePubDate.toString()
        }
        
        if let episodeSummary = self.episodeSummary {
            values["episodeSummary"] = episodeSummary
        }
        
        if let episodeTitle = self.episodeTitle {
            values["episodeTitle"] = episodeTitle
        }
        
        if let startTime = self.startTime {
            values["startTime"] = String(startTime)
        }
        
        if let endTime = self.endTime {
            values["endTime"] = String(endTime)
        }
        
        if let clipTitle = self.clipTitle {
            values["title"] = clipTitle
        }
        
        if let ownerName = self.ownerName {
            values["ownerName"] = ownerName
        }
        
        if let ownerId = self.ownerId {
            values["ownerId"] = ownerId
        }
        
        if let isPublic = self.isPublic {
            values["isPublic"] = isPublic.description
        }
        
        return values
    }
    
    func convertToMediaRefUpdateBody() -> [String: Any] {
        var body:[String: Any] = [:]
        
        if let mediaRefId = self.mediaRefId {
            body["id"] = mediaRefId
        }
        
        if let startTime = self.startTime {
            body["startTime"] = String(startTime)
        }
        
        if let endTime = self.endTime {
            body["endTime"] = String(endTime)
        }
        
        if let clipTitle = self.clipTitle {
            body["title"] = clipTitle
        }
        
        if let isPublic = self.isPublic {
            body["isPublic"] = isPublic.description
        }
        
        return body
    }
    
    func updateMediaRefOnServer(completion: @escaping (Bool) -> Void) {
        if let url = URL(string: BASE_URL + "clips") {
            
            var request = URLRequest(url: url, cachePolicy: NSURLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 20)
            
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            request.httpMethod = "PUT"
            
            if let idToken = UserDefaults.standard.string(forKey: "idToken") {
                request.setValue(idToken, forHTTPHeaderField: "Authorization")
            }
            
            let putBody = self.convertToMediaRefUpdateBody()
            
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: putBody, options: JSONSerialization.WritingOptions())
                
                showNetworkActivityIndicator()
                
                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    hideNetworkActivityIndicator()
                    
                    guard error == nil else {
                        DispatchQueue.main.async {
                            completion(false)
                        }
                        return
                    }
                    
                    PVMediaPlayer.shared.loadPlayerHistoryItem(item: self)
                    
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name:NSNotification.Name(rawValue: kClipUpdated), object: self, userInfo: nil)
                        completion(true)
                    }
                }
                
                task.resume()
                
            } catch {
                print(error)
            }
            
        }
    }
    
    func saveToServerAsMediaRef(completion: @escaping (_ mediaRef: MediaRef?) -> Void) {
        
        if let url = URL(string: BASE_URL + "clips/") {
            
            var request = URLRequest(url: url, cachePolicy: NSURLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 20)
            
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            
            if let idToken = UserDefaults.standard.string(forKey: "idToken") {
                request.setValue(idToken, forHTTPHeaderField: "Authorization")
            }
            
            let postBody = self.convertToMediaRefPostString()
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: postBody, options: JSONSerialization.WritingOptions())
                
                showNetworkActivityIndicator()
                
                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    
                    hideNetworkActivityIndicator()
                    
                    guard error == nil else {
                        DispatchQueue.main.async {
                            completion(nil)
                        }
                        return
                    }
                    
                    if let data = data {
                        do {
                            let mediaRef: MediaRef?
                            
                            if let item = try JSONSerialization.jsonObject(with: data, options: []) as? [String:Any] {
                                mediaRef = MediaRef.jsonToMediaRef(item: item)
                                
                                DispatchQueue.main.async {
                                    completion(mediaRef)
                                }
                            }
                        } catch {
                            print("Error: " + error.localizedDescription)
                        }
                    }
                    
                }
                
                task.resume()
                
            } catch {
                print(error.localizedDescription)
            }
            
        }
        
    }
    
    func copyPlayerHistoryItem() -> PlayerHistoryItem {
        let copy = PlayerHistoryItem(mediaRefId: mediaRefId, podcastId: podcastId, podcastFeedUrl: podcastFeedUrl, podcastTitle: podcastTitle, podcastImageUrl: podcastImageUrl, episodeDuration: episodeDuration, episodeId: episodeId, episodeMediaUrl: episodeMediaUrl, episodeTitle: episodeTitle, episodeImageUrl: episodeImageUrl, episodeSummary: episodeSummary, episodePubDate: episodePubDate, startTime: startTime, endTime: endTime, clipTitle: clipTitle, ownerName: ownerName, ownerId: ownerId, hasReachedEnd: false, lastPlaybackPosition: lastPlaybackPosition, lastUpdated: lastUpdated, isPublic: isPublic)
        return copy
    }
    
    func removeClipData() {
        self.clipTitle = nil
        self.startTime = nil
        self.endTime = nil
        self.hasReachedEnd = false
        self.mediaRefId = nil
        self.ownerId = nil
        self.ownerName = nil
    }
    
}
