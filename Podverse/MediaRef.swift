//
//  MediaRef.swift
//  Podverse
//
//  Created by Mitchell Downey on 5/27/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

import Foundation

class MediaRef {
    var id: String?
    var title: String?
    var startTime: Int64?
    var endTime: Int64?
    var episodeTitle: String?
    var episodeMediaUrl: String?
    var episodePubDate: Date?
    var episodeSummary: String?
    var podcastTitle: String?
    var podcastFeedUrl: String?
    var podcastImageUrl: String?
    
    static func jsonToMediaRef(item: [String:Any]) -> MediaRef {

        let mediaRef = MediaRef()
        
        mediaRef.id = item["id"] as? String
        mediaRef.title = item["title"] as? String
        mediaRef.startTime = item["startTime"] as? Int64
        mediaRef.endTime = item["endTime"] as? Int64
        
        mediaRef.episodeTitle = item["episodeTitle"] as? String
        mediaRef.episodeMediaUrl = item["episodeMediaURL"] as? String
        mediaRef.episodeSummary = item["episodeSummary"] as? String
        
        mediaRef.podcastTitle = item["podcastTitle"] as? String
        mediaRef.podcastFeedUrl = item["podcastFeedURL"] as? String
        mediaRef.podcastImageUrl = item["podcastImageURL"] as? String
        
        if let episodePubDate = item["episodePubDate"] as? String {
            mediaRef.episodePubDate = episodePubDate.toServerDate()
        }
        
        return mediaRef
        
    }
    
    static func retrieveMediaRefsFromServer(episodeMediaUrl: String? = nil, podcastFeedUrls: [String] = [], onlySubscribed: Bool? = nil, sortingType: ClipSorting? = nil, page: Int? = 1, completion: @escaping (_ mediaRefs:[MediaRef]?) -> Void) {
        
        if let url = URL(string: BASE_URL + "api/clips") {
            
            let request = NSMutableURLRequest(url: url, cachePolicy: NSURLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 60)
            
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            request.httpMethod = "POST"
            
            var values: [String: Any] = [:]
            
            if let episodeMediaUrl = episodeMediaUrl {
                values["episodeMediaURL"] = episodeMediaUrl
            }
            
            if podcastFeedUrls.count > 0 {
                values["podcastFeedURLs"] = podcastFeedUrls
            }
            
            if let sortingType = sortingType {
                values["filterType"] = sortingType.requestParam
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
