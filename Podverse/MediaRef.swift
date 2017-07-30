//
//  MediaRef.swift
//  Podverse
//
//  Created by Mitchell Downey on 5/27/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

import Foundation

class MediaRef {
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
    
    static func retrieveMediaRefsFromServer(episodeMediaUrl: String? = nil, podcastFeedUrl: String? = nil, onlySubscribed: Bool? = nil, completion: @escaping (_ mediaRefs:[MediaRef]?) -> Void) {
        if let url = URL(string: "https://podverse.fm/api/clips") {
            var request = URLRequest(url: url, cachePolicy: NSURLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 60)
            request.httpMethod = "POST"
            
            var postString:String?
            
            if let episodeMediaUrl = episodeMediaUrl {
                postString = "episodeMediaURL=" + episodeMediaUrl
            }
            
            if let podcastFeedUrl = podcastFeedUrl {
                postString = "podcastFeedURL=" + podcastFeedUrl
            }
            
            if let postString = postString {
                request.httpBody = postString.data(using: .utf8)
            }
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in

                guard error == nil else {
                    DispatchQueue.main.async {
                        completion([])
                    }
                    return
                }
                
                if let data = data {
                    do {
                        var mediaRefs = [MediaRef]()
                        
                        if let responseJSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String:Any] {
                            if let clips = responseJSON["data"] as? [[String:Any]] {
                                for item in clips {
                                    let mediaRef = MediaRef()
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
                                    
                                    mediaRefs.append(mediaRef)
                                }
                            }
                        }
                        
                        DispatchQueue.main.async {
                            completion(mediaRefs)
                        }
                    } catch {
                        print("Error")
                    }
                }
            }
            
            task.resume()
        }
    }
}
