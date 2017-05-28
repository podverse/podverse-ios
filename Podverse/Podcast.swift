//
//  Podcast.swift
//  Podverse
//
//  Created by Creon on 12/24/16.
//  Copyright © 2016 Podverse LLC. All rights reserved.
//

import Foundation
import CoreData

class Podcast: NSManagedObject {
    @NSManaged public var feedUrl: String
    @NSManaged public var imageData: Data?
    @NSManaged public var imageThumbData: Data?
    @NSManaged public var imageUrl: String?
    @NSManaged public var author: String?
    @NSManaged public var link: String? // generally the home page
    @NSManaged public var itunesImage: Data?
    @NSManaged public var itunesImageUrl: String?
    @NSManaged public var lastBuildDate: Date?
    @NSManaged public var lastPubDate: Date?
    @NSManaged public var summary: String?
    @NSManaged public var title: String
    @NSManaged public var isSubscribed: Bool
    @NSManaged public var isFollowed: Bool
    @NSManaged public var categories: String?
    @NSManaged public var episodes: Set<Episode>
    var totalClips:Int {
        get {
            var totalClips = 0
            for episode in episodes {
                totalClips += episode.clips.count
            }
            
            return totalClips
        }
    }
    
    func addEpisodeObject(value: Episode) {
        self.mutableSetValue(forKey: "episodes").add(value)
    }
    
    func removeEpisodeObject(value: Episode) {
        self.mutableSetValue(forKey: "episodes").remove(value)
    }
}
