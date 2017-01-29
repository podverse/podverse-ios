//
//  Clip.swift
//  Podverse
//
//  Created by Creon on 12/24/16.
//  Copyright © 2016 Podverse LLC. All rights reserved.
//

import Foundation
import CoreData

class Clip: NSManagedObject {
    @NSManaged var mediaRefId: String
    @NSManaged var podverseURL: String?
    @NSManaged var ownerId: String
    @NSManaged var ownerName: String?
    @NSManaged var title: String?
    @NSManaged var startTime: NSNumber
    @NSManaged var endTime: NSNumber?
    @NSManaged var dateCreated: Date?
    @NSManaged var lastUpdated: Date?
    @NSManaged var permission:String
    @NSManaged var episode: Episode
    @NSManaged var playlists: Set<Playlist>?

    var permissionState:SharePermission {
        get {
            return SharePermission(rawValue:permission) ?? .isPublic
        }
        set {
            self.permission = newValue.rawValue
        }
    }

    var duration: NSNumber? {
        get {
            var duration: NSNumber? = nil
            
            if let eTime = endTime?.intValue, (eTime > startTime.intValue) {
                duration = NSNumber(value: eTime - startTime.intValue)
            }
            
            return duration
        }
    }
}
