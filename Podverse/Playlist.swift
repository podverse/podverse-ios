//
//  Playlist.swift
//  Podverse
//
//  Created by Creon on 12/24/16.
//  Copyright © 2016 Podverse LLC. All rights reserved.
//

import Foundation
import CoreData

class Playlist:NSManagedObject {
    
    @NSManaged var id:String?
    @NSManaged var podverseURL: String?
    
    @NSManaged var ownerId:String
    @NSManaged var ownerName:String?
    
    @NSManaged var title: String?
    
    @NSManaged var dateCreated: NSDate?
    @NSManaged var lastUpdated: NSDate?
    
    @NSManaged var sharePermission: String?
    
    @NSManaged var isMyEpisodes: Bool
    @NSManaged var isMyClips: Bool
    
    @NSManaged var episodes: Set<Episode>?
    @NSManaged var clips: Set<Clip>?
    
    var allItems: [Any] {
        get {
            var allItemsArray: [Any] = []
            if let episodes = episodes {
                for episode in episodes {
                    allItemsArray.append(episode)
                }
            }
            if let clips = clips {
                for clip in clips {
                    allItemsArray.append(clip)
                }
            }
            
            return allItemsArray
        }
    }
    
    func addEpisodeObject(value: Episode) {
        self.mutableSetValue(forKey: "episodes").add(value)
    }
    
    func addClipObject(value: Clip) {
        self.mutableSetValue(forKey: "clips").add(value)
    }
    
    private func removeEpisodeObject(_ episode: Episode) {
        self.mutableSetValue(forKey: "episodes").remove(episode)
        
        let alsoDeletePodcast = PVDeleter.checkIfPodcastShouldBeRemoved(podcast: episode.podcast, isUnsubscribing: false, isUnfollowing: false, moc:episode.managedObjectContext)
        
        if alsoDeletePodcast {
            PVDeleter.deletePodcast(podcastID: episode.podcast.objectID, completionBlock: nil)
        }
        
    }
    
    private func removeClipObject(_ clip: Clip) {
        self.mutableSetValue(forKey: "clips").remove(clip)
        
        let alsoDeletePodcast = PVDeleter.checkIfPodcastShouldBeRemoved(podcast: clip.episode.podcast, isUnsubscribing: false, isUnfollowing: false, moc:clip.managedObjectContext)
        
        if alsoDeletePodcast {
            PVDeleter.deletePodcast(podcastID: clip.episode.podcast.objectID, completionBlock: nil)
        }
    }
    
    func removePlaylistItem(value: Any) {
        if let episode = value as? Episode {
            removeEpisodeObject(episode)
        }
        else if let clip = value as? Clip {
            removeClipObject(clip)
        }
        else {
            print("Object not a playlist item")
        }
    }
}
