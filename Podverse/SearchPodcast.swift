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
    
    var buzzScore: String?
    var categories: String?
    var description: String?
    var feedUrl: String?
    var hosts: String?
    var imageUrl: String?
    var lastEpisodeTitle: String?
    var lastPubDate: String?
    var network: String?
    var id: String?
    var searchEpisodes = [SearchEpisode]()
    var title: String?
    
    static func convertJSONToSearchPodcast (_ json: [String:Any]) -> SearchPodcast {
        
        let searchPodcast = SearchPodcast()
        
        if let id = json["id"] as? String {
            searchPodcast.id = id
        }
        
        if let title = json["title"] as? String {
            searchPodcast.title = title
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
        
        if let episodes = json["episodes"] as? [[String:Any]] {
            for episode in episodes {
                let searchEpisode = SearchEpisode.convertJSONToSearchEpisode(episode)
                searchPodcast.searchEpisodes.append(searchEpisode)
            }
        }
        
        return searchPodcast
        
    }
    
    static func retrievePodcastFromServer(id: String?, completion: @escaping (_ podcast:SearchPodcast?) -> Void) {
        
        if let id = id {
            
            if let url = URL(string: BASE_URL + "api/podcasts?id=" + id) {
                var request = URLRequest(url: url, cachePolicy: NSURLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 60)
                request.httpMethod = "GET"
                
                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    
                    guard error == nil else {
                        DispatchQueue.main.async {
                            completion(nil)
                        }
                        return
                    }
                    
                    if let data = data {
                        do {
                            var searchPodcast = SearchPodcast()
                            
                            if let podcastJSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String:Any] {
                                searchPodcast = convertJSONToSearchPodcast(podcastJSON)
                            }
                            
                            DispatchQueue.main.async {
                                completion(searchPodcast)
                            }
                            
                        } catch {
                            print("Error: " + error.localizedDescription)
                        }
                    }
                    
                }
                
                task.resume()
            }
            
        } else {
            completion(nil)
        }
        
    }
    
    static func authorityFeedUrlForPodcast(id: String, completion: @escaping (_ podverseId: String?) -> Void) {
        
        if let url = URL(string: BASE_URL + "api/podcasts/authorityFeedUrl?id=" + id) {
            
            var request = URLRequest(url: url, cachePolicy: NSURLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 60)
            request.httpMethod = "GET"
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                
                guard error == nil else {
                    print(error)
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }
                
                if let data = data, let urlString = String(data: data, encoding: .utf8) {
                    DispatchQueue.main.async {
                        completion(urlString)
                    }
                }
                
            }
            
            task.resume()
        }
    }
    
    static func searchPodcastsByTitle(title: String, completion: @escaping (_ podcasts: [SearchPodcast]?) -> Void) {
        if let encodedTitle = title.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) {
            if let url = URL(string: BASE_URL + "podcasts?title=" + encodedTitle) {
                
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
                            DispatchQueue.main.async {
                                completion([])
                            }
                        }
                    }
                    
                }
                
                task.resume()
                
            }
        }
    }
    
    static func showSearchPodcastActions(searchPodcast: SearchPodcast, vc: UIViewController) {
        
        if let id = searchPodcast.id {

            let podcastActions = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            if let podcast = Podcast.podcastForId(id: id) {
                podcastActions.addAction(UIAlertAction(title: "Unsubscribe", style: .default, handler: { action in
                    PVDeleter.deletePodcast(feedUrl: podcast.feedUrl)
                }))
            } else {
                podcastActions.addAction(UIAlertAction(title: "Subscribe", style: .default, handler: { action in
                    self.authorityFeedUrlForPodcast(id: id) { feedUrl in
                        if let feedUrl = feedUrl {
                            PVSubscriber.subscribeToPodcast(feedUrlString: feedUrl, podcastId: id)
                        }
                    }
                }))
            }
            
            podcastActions.addAction(UIAlertAction(title: "About", style: .default, handler: { action in
                vc.performSegue(withIdentifier: "Show Search Podcast", sender: "About")
            }))
            
            podcastActions.addAction(UIAlertAction(title: "Episodes", style: .default, handler: { action in
                vc.performSegue(withIdentifier: "Show Search Podcast", sender: "Episodes")
            }))
            
            podcastActions.addAction(UIAlertAction(title: "Clips", style: .default, handler: { action in
                vc.performSegue(withIdentifier: "Show Search Podcast", sender: "Clips")
            }))
            
            vc.present(podcastActions, animated: true, completion: nil)
        }
        
    }
        
}
