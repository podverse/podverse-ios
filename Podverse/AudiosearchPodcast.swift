//
//  AudiosearchPodcast.swift
//  Podverse
//
//  Created by Creon on 12/24/16.
//  Copyright © 2016 Podverse LLC. All rights reserved.
//

import Foundation
import UIKit

class AudiosearchPodcast {
    var id: Int64?
    var buzzScore: String?
    var categories: String?
    var description: String?
    var hosts: String?
    var imageThumbUrl: String?
    var imageUrl: String?
    var network: String?
    var rssUrl: String?
    var title: String?
    
    static func convertJSONToAudiosearchPodcast (_ json: AnyObject) -> AudiosearchPodcast? {
        let podcast = AudiosearchPodcast()
        
        podcast.id = json["id"] as? Int64
        
        podcast.buzzScore = json["buzz_score"] as? String
        
        if let categories = json["categories"] as? [[String:Any]] {
            var categoriesString = ""
            for category in categories {
                if let c = category["name"] as? String {
                    categoriesString += c + ", "
                }
            }
            categoriesString = String(categoriesString.characters.dropLast(2))
            podcast.categories = categoriesString
        }
        
        podcast.description = json["description"] as? String
        
        if let hosts = json["hosts"] as? [String] {
            var hostsString = ""
            for host in hosts {
                hostsString += host + ", "
            }
            hostsString = String(hostsString.characters.dropLast(2))
            podcast.hosts = hostsString
        }
        
        if let imageUrls = json["image_urls"] as? [String:Any], let thumbUrl = imageUrls["thumb"] as? String {
            podcast.imageThumbUrl = thumbUrl
        }
        
        if let network = json["network"] as? [String:Any], let name = network["name"] as? String {
            podcast.network = name
        }
        
        podcast.rssUrl = json["rss_url"] as? String
        
        podcast.title = json["title"] as? String
        
        return podcast
    }
    
    static func retrievePodcastFromServer(id: Int64?, completion: @escaping (_ podcast:AudiosearchPodcast?) -> Void) {
        
        if let id = id {
            
            AudioSearchClientSwift.retrievePodcast(id: id, { serviceResponse in
                
                if let response = serviceResponse.0, let podcast = AudiosearchPodcast.convertJSONToAudiosearchPodcast(response) {
                    completion(podcast)
                }
                
                if let error = serviceResponse.1 {
                    print(error.localizedDescription)
                    completion(nil)
                }
                
            })
            
        } else {
            completion(nil)
        }
        
    }
    
    static func showAudiosearchPodcastActions(podcast: AudiosearchPodcast, vc: UIViewController) {
        if let feedUrl = podcast.rssUrl {
            var isSubscribed = false
    
            if let _ = Podcast.podcastForFeedUrl(feedUrlString: feedUrl) {
            isSubscribed = true
            }
    
            let podcastActions = UIAlertController(title: "", message: "", preferredStyle: .actionSheet)
    
            if isSubscribed == true {
            podcastActions.addAction(UIAlertAction(title: "Unsubscribe", style: .default, handler: { action in
            PVDeleter.deletePodcast(podcastId: nil, feedUrl: feedUrl)
            }))
            } else {
            podcastActions.addAction(UIAlertAction(title: "Subscribe", style: .default, handler: { action in
            PVSubscriber.subscribeToPodcast(feedUrlString: feedUrl)
            }))
            }
    
            podcastActions.addAction(UIAlertAction(title: "About", style: .default, handler: { action in
            vc.performSegue(withIdentifier: "Show Audiosearch Podcast About", sender: nil)
            }))
    
            podcastActions.addAction(UIAlertAction(title: "Clips", style: .default, handler: { action in
            vc.performSegue(withIdentifier: "Show Audiosearch Podcast Clips", sender: nil)
            }))
    
            podcastActions.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
    
            vc.present(podcastActions, animated: true, completion: nil)
        }
    }
    
}
