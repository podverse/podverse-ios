//
//  MediaRef.swift
//  Podverse
//
//  Created by Mitchell Downey on 5/27/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

import UIKit

class MediaRef {
    
    var id:String?
    var title:String?
    var startTime:Int64?
    var endTime:Int64?
    var episodeId:String?
    var episodeTitle:String?
    var episodeMediaUrl:String?
    var episodePubDate:Date?
    var episodeSummary:String?
    var episodeDuration:String?
    var podcastId:String?
    var podcastFeedUrl:String?
    var podcastImageUrl:String?
    var podcastTitle:String?
    var ownerId:String?
    var ownerName:String?
    var isPublic:Bool? = false
    
    static func jsonToMediaRef(item: [String:Any]) -> MediaRef {
        let mediaRef = MediaRef()
        
        mediaRef.id = item["id"] as? String
        mediaRef.title = item["title"] as? String
        mediaRef.startTime = item["startTime"] as? Int64
        mediaRef.endTime = item["endTime"] as? Int64
        
        mediaRef.episodeId = item["episodeId"] as? String
        mediaRef.episodeTitle = item["episodeTitle"] as? String
        mediaRef.episodeMediaUrl = item["episodeMediaUrl"] as? String
        mediaRef.episodeSummary = item["episodeSummary"] as? String
        mediaRef.episodeDuration = item["episodeDuration"] as? String
        
        mediaRef.podcastTitle = item["podcastTitle"] as? String
        mediaRef.podcastId = item["podcastId"] as? String
        mediaRef.podcastFeedUrl = item["podcastFeedUrl"] as? String
        mediaRef.podcastImageUrl = item["podcastImageUrl"] as? String
        
        mediaRef.ownerId = item["ownerId"] as? String
        mediaRef.ownerName = item["ownerName"] as? String
        
        if let episodePubDate = item["episodePubDate"] as? String {
            mediaRef.episodePubDate = episodePubDate.toServerDate()
        }
        
        mediaRef.isPublic = item["isPublic"] as? Bool
        
        return mediaRef
    }
    
    static func jsonToPlayerHistoryItem(json: [String:Any]) -> PlayerHistoryItem? {
        if let isPublic = json["isPublic"] as? Bool {
            let mediaRefId = json["id"] as? String
            let podcastId = json["podcastId"] as? String
            let podcastFeedUrl = json["podcastFeedUrl"] as? String
            let podcastTitle = json["podcastTitle"] as? String
            let podcastImageUrl = json["podcastImageUrl"] as? String
            let episodeDuration = json["episodeDuration"] as? Int64
            let episodeId = json["episodeId"] as? String
            let episodeMediaUrl = json["episodeMediaUrl"] as? String
            let episodeTitle = json["episodeTitle"] as? String
            let episodeImageUrl = json["episodeImageUrl"] as? String
            let episodeSummary = json["episodeSummary"] as? String
            let episodePubDate = (json["episodePubDate"] as? String)?.toServerDate()
            let lastUpdated = (json["lastUpdated"] as? String)?.toServerDate()
            let startTime = json["startTime"] as? Int64
            let endTime = json["endTime"] as? Int64
            let title = json["title"] as? String
            let ownerName = json["ownerName"] as? String
            let ownerId = json["ownerId"] as? String
            
            let item = PlayerHistoryItem(mediaRefId: mediaRefId, podcastId: podcastId, podcastFeedUrl: podcastFeedUrl, podcastTitle: podcastTitle, podcastImageUrl: podcastImageUrl, episodeDuration: episodeDuration, episodeId: episodeId, episodeMediaUrl: episodeMediaUrl, episodeTitle: episodeTitle, episodeImageUrl: episodeImageUrl, episodeSummary: episodeSummary, episodePubDate: episodePubDate, startTime: startTime, endTime: endTime, clipTitle: title, ownerName: ownerName, ownerId: ownerId, hasReachedEnd: false, lastPlaybackPosition: nil, lastUpdated: lastUpdated, isPublic: isPublic)
            
            return item
        }
        
        return nil
    }
    
    static func retrieveMediaRefFromServer(id:String, completion: @escaping (_ item:PlayerHistoryItem?) -> Void) {
        if let url = URL(string: BASE_URL + "api/clips") {
            
            let request = NSMutableURLRequest(url: url, cachePolicy: NSURLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 60)
            
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            request.httpMethod = "POST"
            
            var values: [String: Any] = [:]
            values["id"] = id
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: values, options: [])
            } catch {
                print("Error: \(error.localizedDescription)")
            }
            
            let task = URLSession.shared.dataTask(with: request as URLRequest) { data, response, error in
                
                hideNetworkActivityIndicator()
                guard error == nil else {
                    print("Error: \(error?.localizedDescription ?? "Unknown Error")")
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }
                
                if let data = data {
                    do {
                        if let responseJSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String:Any] {
                            let item = jsonToPlayerHistoryItem(json: responseJSON)
                            DispatchQueue.main.async {
                                completion(item)
                            }
                        }
                    } catch {
                        print("Error: " + error.localizedDescription)
                    }
                }
            }
            
            task.resume()
            
        }
    }
    
    static func retrieveMediaRefsFromServer(episodeMediaUrl: String? = nil, podcastIds: [String] = [], podcastFeedUrls: [String] = [], userId:String? = nil, onlySubscribed: Bool? = nil, sortingTypeRequestParam: String?, page: Int? = 1, completion: @escaping (_ mediaRefs:[MediaRef]?) -> Void) {
        showNetworkActivityIndicator()
        if let url = URL(string: BASE_URL + "api/clips") {
            
            let request = NSMutableURLRequest(url: url, cachePolicy: NSURLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 60)
            
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            request.httpMethod = "POST"
            
            var values: [String: Any] = [:]
            
            if let episodeMediaUrl = episodeMediaUrl {
                values["episodeMediaUrl"] = episodeMediaUrl
            } else if podcastIds.count > 0 {
                values["podcastIds"] = podcastIds
            } else if podcastFeedUrls.count > 0 {
                values["podcastFeedUrls"] = podcastFeedUrls
            } else if let userId = userId {
                values["userId"] = userId
            }
            
            if let sortingTypeRequestParam = sortingTypeRequestParam {
                values["sortType"] = sortingTypeRequestParam
            }
            
            if let page = page {
                values["page"] = String(page)
            }
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: values, options: [])
            } catch {
                print("Error: \(error.localizedDescription)")
            }
            
            let task = URLSession.shared.dataTask(with: request as URLRequest) { data, response, error in

                hideNetworkActivityIndicator()
                guard error == nil else {
                    print("Error: \(error?.localizedDescription ?? "Unknown Error")")
                    DispatchQueue.main.async {
                        completion([])
                    }
                    return
                }
                
                if let data = data {
                    do {
                        var mediaRefs = [MediaRef]()
                        
                        if let responseJSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String:Any] {
                            if let mediaRefsJSON = responseJSON["data"] as? [[String:Any]] {
                                for item in mediaRefsJSON {
                                    let mediaRef = jsonToMediaRef(item: item)
                                    mediaRefs.append(mediaRef)
                                }
                            }
                        }
                        
                        DispatchQueue.main.async {
                            completion(mediaRefs)
                        }
                        
                    } catch {
                        print("Error: " + error.localizedDescription)
                    }
                }
            }
            
            task.resume()
            
        }
    }
    
    static func deleteMediaRefFromServer(id:String, completion: @escaping (Bool) -> Void) {
        if let url = URL(string: BASE_URL + "clips/" + id), let idToken = UserDefaults.standard.string(forKey: "idToken") {
            showNetworkActivityIndicator()
            
            let request = NSMutableURLRequest(url: url, cachePolicy: NSURLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 60)
            
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(idToken, forHTTPHeaderField: "Authorization")
            
            request.httpMethod = "DELETE"
            
            let task = URLSession.shared.dataTask(with: request as URLRequest) { data, response, error in
                hideNetworkActivityIndicator()
                guard error == nil else {
                    print("Error: \(error?.localizedDescription ?? "Unknown Error")")
                    DispatchQueue.main.async {
                        completion(false)
                    }
                    return
                }
                
                completion(true)
            }
            
            task.resume()
        }
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
                time = "Starts:" + startTime.toMediaPlayerString()
            }
        }
        
        return time
    }
    
    func readableClipTitle() -> String {
        if let title = self.title {
            return title
        } else {
            return "(untitled clip)"
        }
    }
    
    func readableDuration() -> String? {
        
        if let startTime = self.startTime {
            
            if let endTime = self.endTime {
                let duration = endTime - startTime
                return duration.toDurationString()
            } else {
                return "until end"
            }
            
        }
        
        return ""
        
    }
    
}
