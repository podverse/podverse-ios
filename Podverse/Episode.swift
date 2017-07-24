//
//  Episode.swift
//  Podverse
//
//  Created by Creon on 12/24/16.
//  Copyright © 2016 Podverse LLC. All rights reserved.
//

import Foundation
import CoreData

class Episode: NSManagedObject {
    @NSManaged var duration: NSNumber?
    @NSManaged var fileName: String?
    @NSManaged var guid: String?
    @NSManaged var link: String?
    @NSManaged var mediaBytes: NSNumber?
    @NSManaged var mediaType: String?
    @NSManaged var mediaUrl: String?
    @NSManaged var pubDate: Date?
    @NSManaged var summary: String?
    @NSManaged var title: String?
    @NSManaged var uuid: String?
    @NSManaged var podcast: Podcast
    
    static func episodeForMediaUrl(mediaUrlString: String, managedObjectContext:NSManagedObjectContext? = nil) -> Episode? {
        let moc = managedObjectContext ?? CoreDataHelper.createMOCForThread(threadType: .mainThread)
        
        let predicate = NSPredicate(format: "mediaUrl == %@", mediaUrlString)
        let episodeSet = CoreDataHelper.fetchEntities(className: "Episode", predicate: predicate, moc:moc) as? [Episode]
        
        return episodeSet?.first
    }
    
    static let episodeKey = "episode"
}


