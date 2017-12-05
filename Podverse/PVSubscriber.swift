//
//  PVSubscriber.swift
//  Podverse
//
//  Created by Mitchell Downey on 5/6/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

import UIKit
import CoreData

class PVSubscriber {
    
    static func subscribeToPodcast(feedUrlString: String?) {
        
        if let feedUrlString = feedUrlString {
            
            // TODO: add error handling / connectivity error
            updatePodcastOnServer(feedUrl: feedUrlString, shouldSubscribe: true) { wasSuccessful in
                //
            }
            
            let feedParser = PVFeedParser(shouldOnlyGetMostRecentEpisode: false, shouldSubscribe: true)
            feedParser.parsePodcastFeed(feedUrlString: feedUrlString)
            
            DispatchQueue.main.async {
                feedParser.delegate = ((UIApplication.shared.keyWindow?.rootViewController as? UITabBarController)?.viewControllers?.first as? UINavigationController)?.topViewController as? PodcastsTableViewController
            }

        }
        
    }
    
    static func unsubscribeFromPodcast(feedUrlString: String?) {
        
        if let feedUrlString = feedUrlString {
            
            // TODO: add error handling / connectivity error
            updatePodcastOnServer(feedUrl: feedUrlString, shouldSubscribe: false) { wasSuccessful in
                //
            }
            
            PVDeleter.deletePodcast(feedUrl: feedUrlString)
            
        }
        
    }
    
    static func checkIfSubscribed(feedUrlString: String?) -> Bool {
        if let feedUrlString = feedUrlString, let _ = Podcast.podcastForFeedUrl(feedUrlString: feedUrlString) {
            return true
        } else {
            return false
        }
    }
    
    static func updatePodcastOnServer(feedUrl:String, shouldSubscribe:Bool, completion: @escaping (_ wasSuccessful:Bool?) -> Void) {
        
        let urlEnding = shouldSubscribe == true ? "subscribe" : "unsubscribe"
        
        if let url = URL(string: BASE_URL + "podcasts/" + urlEnding) {
            var request = URLRequest(url: url, cachePolicy: NSURLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 60)
            request.httpMethod = "POST"
            
            guard let idToken = UserDefaults.standard.string(forKey: "idToken") else {
                return
            }
            
            request.setValue(idToken, forHTTPHeaderField: "authorization")
            
            let postString = "podcastFeedURL=" + feedUrl
            request.httpBody = postString.data(using: .utf8)
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                
                guard error == nil else {
                    DispatchQueue.main.async {
                        completion(false)
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    completion(true)
                }
                
            }
            
            task.resume()
            
        }
        
    }
    
}
