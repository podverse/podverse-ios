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
    
    static func subscribeToPodcast(podcastId: String?, feedUrl: String?) {
        
        if let feedUrl = feedUrl {
            
            // TODO: add error handling / connectivity error
            updatePodcastOnServer(podcastId: podcastId, shouldSubscribe: true) { wasSuccessful in
                //
            }
            
            let feedParser = PVFeedParser(shouldOnlyGetMostRecentEpisode: false, shouldSubscribe: true, podcastId: podcastId)
            feedParser.addToParsingQueue(feedUrlString: feedUrl)
        }
        
    }
    
    static func unsubscribeFromPodcast(podcastId: String?, feedUrl: String?) {
        
        if let podcastId = podcastId {
            
            // TODO: add error handling / connectivity error
            updatePodcastOnServer(podcastId: podcastId, shouldSubscribe: false) { wasSuccessful in
                //
            }
            
            PVDeleter.deletePodcast(podcastId: podcastId, feedUrl: feedUrl)
            
        } else if let feedUrl = feedUrl {
            PVDeleter.deletePodcast(podcastId: nil, feedUrl: feedUrl)
        }
        
    }
    
    static func checkIfSubscribed(podcastId: String?) -> Bool {
        if let podcastId = podcastId, let _ = Podcast.podcastForId(id: podcastId) {
            return true
        } else {
            return false
        }
    }
    
    static func updatePodcastOnServer(podcastId:String?, shouldSubscribe:Bool, completion: @escaping (_ wasSuccessful:Bool?) -> Void) {
        
        let urlEnding = shouldSubscribe == true ? "subscribe" : "unsubscribe"
        
        if let podcastId = podcastId, let url = URL(string: BASE_URL + "podcasts/" + urlEnding) {
            var request = URLRequest(url: url, cachePolicy: NSURLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData, timeoutinterval: 30)
            request.httpMethod = "POST"
            
            guard let idToken = UserDefaults.standard.string(forKey: "idToken") else {
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            request.setValue(idToken, forHTTPHeaderField: "Authorization")
            
            let postString = "podcastId=" + podcastId
            request.httpBody = postString.data(using: .utf8)
            
            showNetworkActivityIndicator()
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                
                hideNetworkActivityIndicator()
                
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
