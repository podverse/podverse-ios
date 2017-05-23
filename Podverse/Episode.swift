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
    @NSManaged var downloadComplete: Bool
    @NSManaged var duration: NSNumber?
    @NSManaged var fileName: String?
    @NSManaged var guid: String?
    @NSManaged var link: String?
    @NSManaged var mediaBytes: NSNumber?
    @NSManaged var mediaType: String?
    @NSManaged var mediaURL: String?
    @NSManaged var pubDate: Date?
    @NSManaged var summary: String?
    @NSManaged var taskIdentifier: NSNumber?
    @NSManaged var taskResumeData: Data?
    @NSManaged var title: String?
    @NSManaged var uuid: String?
    @NSManaged var clips: Set<Clip>
    @NSManaged var podcast: Podcast
    @NSManaged var playlists: Set<Playlist>?
    
    func addClipObject(value: Clip) {
        self.mutableSetValue(forKey: "clips").add(value)
    }
}
