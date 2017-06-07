//
//  PVMediaRefRetriever.swift
//  Podverse
//
//  Created by Mitchell Downey on 6/5/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

import Foundation

// TODO: wtf should we call this thing?
class PVMediaRefRetriever {
    
    static func retrieveMediaRefsFromServer(episodeMediaUrl: String?, podcastFeedUrl: String?, completion: @escaping (_ mediaRefs:[MediaRef]?) -> Void) {
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
                    print(error)
                    return
                }
                
                if let data = data {
                    do {
                        var mediaRefs = [MediaRef]()
                        
                        if let responseJSON = try JSONSerialization.jsonObject(with: data, options: []) as? [[String:Any]] {
                            for item in responseJSON {
                                let mediaRef = MediaRef()
                                mediaRef.title = item["title"] as? String
                                mediaRef.startTime = item["startTime"] as? Int
                                mediaRef.endTime = item["endTime"] as? Int
                                mediaRef.episodeTitle = item["episodeTitle"] as? String
                                mediaRef.episodeMediaUrl = item["episodeMediaUrl"] as? String
                                mediaRef.podcastTitle = item["podcastTitle"] as? String
                                mediaRef.podcastFeedUrl = item["podcastFeedUrl"] as? String
                                mediaRefs.append(mediaRef)
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
