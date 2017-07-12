//
//  PodcastSearchResult.swift
//  Podverse
//
//  Created by Creon on 12/24/16.
//  Copyright © 2016 Podverse LLC. All rights reserved.
//

import Foundation

class PodcastSearchResult {
    var id: String?
    var buzzScore: String?
    var categories: String?
    var description: String?
    var hosts: String?
    var imageUrl: String?
    var network: String?
    var rssUrl: String?
    var scFeed: String?
    var title: String?
    var webProfiles: String?
    
    
    static func convertJSONToSearchResult (json: AnyObject) -> PodcastSearchResult? {
        let podcast = PodcastSearchResult()
        
        podcast.id = json["id"] as? String
        
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
        
        if let imageFiles = json["image_files"] as? [[String:Any]], let imageFile = imageFiles.first, let file = imageFile["file"] as? [String:Any], let thumb = file["thumb"] as? [String:Any], let url = thumb["url"] as? String {
            podcast.imageUrl = url
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
}
