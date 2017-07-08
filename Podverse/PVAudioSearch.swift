//
//  PVAudioSearch.swift
//  Podverse
//
//  Created by Mitchell Downey on 7/8/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

import Foundation

let audiosearchURL = URL(string: "https://www.audiosear.ch")

class PVAudioSearch {
    static func searchPodcasts (term: String?, completion: @escaping (_ podcasts:[PodcastSearchResult]?) -> Void) {
        if let term = term {
            if let url = URL(string: "/api/search/shows/" + term, relativeTo: audiosearchURL) {
                var request = URLRequest(url: url, cachePolicy: NSURLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 60)
                request.httpMethod = "GET"
                
                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    
                    guard error == nil else {
                        DispatchQueue.main.async {
                            completion([])
                        }
                        return
                    }
                    
                    var podcastSearchResults = [PodcastSearchResult]()
                    
                    if let data = data {
                        do {
                            if let responseJSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String:Any] {
                                for podcast in podcastSearchResults {
                                    podcastSearchResults.append(podcast)
                                }
                            }
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
                    
                    DispatchQueue.main.async {
                        completion(podcastSearchResults)
                    }
                    
                }
                
                task.resume()
            }
        }
    }
}


//if let data = data {
//    do {
//        var mediaRefs = [MediaRef]()
//        
//        if let responseJSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String:Any] {
//            if let clips = responseJSON["data"] as? [[String:Any]] {
//                for item in clips {
//                    let mediaRef = MediaRef()
//                    mediaRef.title = item["title"] as? String
//                    mediaRef.startTime = item["startTime"] as? Int
//                    mediaRef.endTime = item["endTime"] as? Int
//                    mediaRef.episodeTitle = item["episodeTitle"] as? String
//                    mediaRef.episodeMediaUrl = item["episodeMediaUrl"] as? String
//                    mediaRef.podcastTitle = item["podcastTitle"] as? String
//                    mediaRef.podcastFeedUrl = item["podcastFeedUrl"] as? String
//                    
//                    if let episodePubDate = item["episodePubDate"] as? String {
//                        let dateFormatter = DateFormatter()
//                        dateFormatter.dateStyle = .short
//                        let date = dateFormatter.date(from: episodePubDate)
//                        mediaRef.episodePubDate = date
//                    }
//                    
//                    mediaRefs.append(mediaRef)
//                }
//            }
//        }
//        
//        DispatchQueue.main.async {
//            completion(mediaRefs)
//        }
//    } catch {
//        print("Error")
//    }
//}


