//
//  SearchEpisode.swift
//  Podverse
//
//  Created by Mitchell Downey on 1/25/18.
//  Copyright © 2018 Podverse LLC. All rights reserved.
//

import Foundation

class SearchEpisode {
    
    var id: String?
    var isPublic: Bool = false
    var mediaUrl: String?
    var pubDate: String?
    var summary: String?
    var title: String?
    
    static func convertJSONToSearchEpisode (_ json: [String:Any]) -> SearchEpisode {
        
        let searchEpisode = SearchEpisode()
        
        if let id = json["id"] as? String {
            searchEpisode.id = id
        }
        
        if let isPublic = json["isPublic"] as? Bool {
            searchEpisode.isPublic = isPublic
        }
        
        if let mediaUrl = json["mediaUrl"] as? String {
            searchEpisode.mediaUrl = mediaUrl
        }
        
        if let pubDate = json["pubDate"] as? String {
            searchEpisode.pubDate = pubDate
        }
        
        if let summary = json["summary"] as? String {
            searchEpisode.summary = summary
        }
        
        if let title = json["title"] as? String {
            searchEpisode.title = title
        }
        
        return searchEpisode
        
    }
}
