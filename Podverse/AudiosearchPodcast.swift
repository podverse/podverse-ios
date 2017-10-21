//
//  AudiosearchPodcast.swift
//  Podverse
//
//  Created by Creon on 12/24/16.
//  Copyright © 2016 Podverse LLC. All rights reserved.
//

import Foundation

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
    var scFeed: String?
    var title: String?
    var webProfiles: String?
    
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
        podcast.scFeed = json["sc_feed"] as? String
        podcast.title = json["title"] as? String
        podcast.webProfiles = json["web_profiles"] as? String
        
        return podcast
    }
    
    static func retrievePodcastFromServer(id: Int64?, completion: @escaping (_ podcast:AudiosearchPodcast?) -> Void) {
        
        if let id = id {
            
            AudioSearchClientSwift.retrievePodcast(id: id, onCompletion: { serviceResponse in
                
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
    
}
