//
//  MediaRef.swift
//  Podverse
//
//  Created by Mitchell Downey on 5/27/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

import Foundation

protocol MediaRefDelegate {
    func mediaRefsRetrievedFromServer()
}

class MediaRef {
    var title:String?
    var startTime:Int?
    var endTime:Int?
    var episodeTitle:String?
    var episodeMediaUrl:String?
    var episodePubDate: Date?
    var podcastTitle:String?
    var podcastFeedUrl:String?
    
    var delegate:MediaRefDelegate?
    static let shared = MediaRef()
    
    func retrieveMediaRefsFromServer(episodeMediaUrl: String? = nil, podcastFeedUrl: String? = nil, onlySubscribed: Bool? = nil, completion: @escaping (_ mediaRefs:[MediaRef]?) -> Void) {
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
                                    mediaRef.startTime = item["startTime"] as? Int
                                    mediaRef.endTime = item["endTime"] as? Int
                                    mediaRef.episodeTitle = item["episodeTitle"] as? String
                                    mediaRef.episodeMediaUrl = item["episodeMediaUrl"] as? String
                                    mediaRef.podcastTitle = item["podcastTitle"] as? String
                                    mediaRef.podcastFeedUrl = item["podcastFeedUrl"] as? String
                                    
                                    if let episodePubDate = item["episodePubDate"] as? String {
                                        let dateFormatter = DateFormatter()
                                        dateFormatter.dateStyle = .short
                                        let date = dateFormatter.date(from: episodePubDate)
                                        mediaRef.episodePubDate = date
                                    }
                                    
                                    mediaRefs.append(mediaRef)
                                }
                            }
                        }
                        
                        DispatchQueue.main.async {
                            self.delegate?.mediaRefsRetrievedFromServer()
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
