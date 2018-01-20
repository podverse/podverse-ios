//
//  SearchPodcast.swift
//  Podverse
//
//  Created by Creon on 12/24/16.
//  Copyright © 2016 Podverse LLC. All rights reserved.
//

import Foundation
import UIKit

class SearchPodcast {
    var id: String?
    var buzzScore: String?
    var categories: String?
    var description: String?
    var hosts: String?
    var imageThumbUrl: String?
    var imageUrl: String?
    var lastEpisodeTitle: String?
    var lastPubDate: String?
    var network: String?
    var rssUrl: String?
    var title: String?
    
    static func convertJSONToSearchPodcast (_ json: [String:Any]) -> SearchPodcast {
        
        let searchPodcast = SearchPodcast()
        
        if let id = json["id"] as? String {
            searchPodcast.id = id
        }
        
        if let t = json["title"] as? String {
            searchPodcast.title = t
        }
        
        if let categories = json["categories"] as? [String] {
            var categoryString = ""
            for category in categories {
                categoryString += category
                if category != categories.last {
                    categoryString += ", "
                }
            }
            searchPodcast.categories = categoryString
        }
        
        if let imageUrl = json["imageUrl"] as? String {
            searchPodcast.imageUrl = imageUrl
        }
        
        if let author = json["author"] as? String {
            searchPodcast.hosts = author
        }
        
        if let lastPubDate = json["lastPubDate"] as? String {
            searchPodcast.lastPubDate = lastPubDate
        }
        
        if let lastEpisodeTitle = json["lastEpisodeTitle"] as? String {
            searchPodcast.lastEpisodeTitle = lastEpisodeTitle
        }
        
        return searchPodcast
        
    }
    
    static func retrievePodcastFromServer(id: String?, completion: @escaping (_ podcast:SearchPodcast?) -> Void) {
        
        if let id = id {
            
//            SearchClientSwift.retrievePodcast(id: id, { serviceResponse in
//
//                if let response = serviceResponse.0, let podcast = SearchPodcast.convertJSONToSearchPodcast(response) {
//                    completion(podcast)
//                }
//
//                if let error = serviceResponse.1 {
//                    print(error.localizedDescription)
//                    completion(nil)
//                }
//
//            })
            
        } else {
            completion(nil)
        }
        
    }
    
    static func searchPodcastsByTitle(title: String, completion: @escaping (_ podcasts: [SearchPodcast]?) -> Void) {
        
        if let url = URL(string: BASE_URL + "podcasts?title=" + title) {
            
            var request = URLRequest(url: url, cachePolicy: NSURLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 60)
            request.httpMethod = "GET"
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                
                guard error == nil else {
                    DispatchQueue.main.async {
                        completion([])
                    }
                    return
                }
                
                if let data = data {
                    do {
                        var searchPodcasts = [SearchPodcast]()
                        
                        if let podcastsJSON = try JSONSerialization.jsonObject(with: data, options: []) as? [[String:Any]] {
                            for item in podcastsJSON {
                                let searchPodcast = convertJSONToSearchPodcast(item)
                                searchPodcasts.append(searchPodcast)
                            }
                        }
                        
                        DispatchQueue.main.async {
                            completion(searchPodcasts)
                        }
                        
                    } catch {
                        print("Error: " + error.localizedDescription)
                    }
                }
                
            }
            
            task.resume()
            
        }
        
    }
    
    static func showSearchPodcastActions(podcast: SearchPodcast, vc: UIViewController) {
        
        if let feedUrl = podcast.rssUrl {
            var isSubscribed = false
            
            if let _ = Podcast.podcastForFeedUrl(feedUrlString: feedUrl) {
                isSubscribed = true
            }
            
            let podcastActions = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            if isSubscribed == true {
                podcastActions.addAction(UIAlertAction(title: "Unsubscribe", style: .default, handler: { action in
                    PVSubscriber.unsubscribeFromPodcast(feedUrlString: feedUrl)
                }))
            } else {
                podcastActions.addAction(UIAlertAction(title: "Subscribe", style: .default, handler: { action in
                    DispatchQueue.global().async {
                        PVSubscriber.subscribeToPodcast(feedUrlString: feedUrl)
                    }
                }))
            }
            
            podcastActions.addAction(UIAlertAction(title: "About", style: .default, handler: { action in
                vc.performSegue(withIdentifier: "Show Search Podcast About", sender: nil)
            }))
            
            podcastActions.addAction(UIAlertAction(title: "Clips", style: .default, handler: { action in
                vc.performSegue(withIdentifier: "Show Search Podcast Clips", sender: nil)
            }))
            
            podcastActions.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            vc.present(podcastActions, animated: true, completion: nil)
        }
    }
    
}
