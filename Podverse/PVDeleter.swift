//
//  PVDeleter.swift
//  Podverse
//
//  Created by Creon on 12/24/16.
//  Copyright © 2016 Podverse LLC. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class PVDeleter {
    
    static func deletePodcast(podcastID: NSManagedObjectID, completionBlock:(()->Void)?) {
        let moc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        moc.parent = CoreDataHelper.shared.managedObjectContext
        let podcast = CoreDataHelper.fetchEntityWithID(objectId: podcastID, moc: moc) as! Podcast
        let episodesToRemove = podcast.episodes
        
        // Delete each episode from the moc, cancel current downloadTask, and remove episode from the episodeDownloadArray
        for episode in episodesToRemove {
            let episodeToRemove = CoreDataHelper.fetchEntityWithID(objectId: episode.objectID, moc: moc) as! Episode
            PVDeleter.deleteEpisode(episodeID: episodeToRemove.objectID)
        }
        
        moc.delete(podcast)
        
        moc.saveData({
            completionBlock?()
        })
    }
    
    static func checkIfPodcastShouldBeRemoved(podcast: Podcast, isUnsubscribing: Bool, isUnfollowing: Bool, moc:NSManagedObjectContext?) -> Bool {
        guard let moc = moc else {
            return true
        }
        
        var alsoDelete = true
        
        if isUnsubscribing == false || isUnfollowing == false {
            if podcast.isSubscribed == true || podcast.isFollowed == true {
                alsoDelete = false
                return alsoDelete
            }
        }
        
        if let allPlaylists = CoreDataHelper.fetchEntities(className: "Playlist", predicate: nil, moc:moc) as? [Playlist] {
            outerLoop: for playlist in allPlaylists {
                for item in playlist.allItems {
                    if let episode = item as? Episode {
                        for podcastEpisode in podcast.episodes {
                            if (podcastEpisode.objectID == episode.objectID) {
                                alsoDelete = false
                                break outerLoop
                            }
                        }
                    }
                    else if let clip = item as? Clip {
                        for podcastEpisode in podcast.episodes {
                            for podcastClip in podcastEpisode.clips {
                                if clip.objectID == podcastClip.objectID {
                                    alsoDelete = false
                                    break outerLoop
                                }
                            }
                        }
                    }
                }
            }
        }
        
        return alsoDelete
    }
    
    static func deleteEpisode(episodeID: NSManagedObjectID) {
        let moc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        moc.parent = CoreDataHelper.shared.managedObjectContext
        
        let episode = CoreDataHelper.fetchEntityWithID(objectId: episodeID, moc: moc) as! Episode
        
        // Get the downloadSession, and if there is a downloadSession with a matching taskIdentifier as episode's taskIdentifier, then cancel the downloadSession
        let episodePodcastFeedURL = episode.podcast.feedURL
        let downloadSession = PVDownloader.shared.downloadSession
        downloadSession?.getTasksWithCompletionHandler { dataTasks, uploadTasks, downloadTasks in
            for episodeDownloadTask in downloadTasks {
                if  let _ = DownloadingEpisodeList.shared.downloadingEpisodes.first(where:{ $0.taskIdentifier == episodeDownloadTask.taskIdentifier && $0.podcastRSSFeedURL == episodePodcastFeedURL })  {
                    episodeDownloadTask.cancel()
                }
            }
        }
        
        // If the episode is currently in the episodeDownloadArray, then delete the episode from the episodeDownloadArray
        DownloadingEpisodeList.removeDownloadingEpisodeWithMediaURL(mediaURL: episode.mediaURL)
        
        DispatchQueue.main.async {
            if let tabBarCntrl = (UIApplication.shared.delegate as! AppDelegate).window?.rootViewController as? UITabBarController {
                if let badgeValue = tabBarCntrl.tabBar.items?[TabItems.Downloads.index].badgeValue, let badgeInt = Int(badgeValue) {
                    tabBarCntrl.tabBar.items?[TabItems.Downloads.index].badgeValue = "\(badgeInt - 1)"
                    if tabBarCntrl.tabBar.items?[TabItems.Downloads.index].badgeValue == "0" {
                        tabBarCntrl.tabBar.items?[TabItems.Downloads.index].badgeValue = nil
                    }
                }
            }
            
            // If the episode is currently now playing, then remove the now playing episode, and remove the Player button from the navbar using kPlayerHasNoItem
//            if let nowPlayingEpisode = PVMediaPlayer.sharedInstance.nowPlayingEpisode {
//                if episode.objectID == nowPlayingEpisode.objectID {
//                    PVMediaPlayer.sharedInstance.avPlayer.pause()
//                    PVMediaPlayer.sharedInstance.nowPlayingEpisode = nil
//                    NSUserDefaults.standardUserDefaults().removeObjectForKey(Constants.kLastPlayingEpisodeURL)
//                    
//                    NSNotificationCenter.defaultCenter().postNotificationName(Constants.kPlayerHasNoItem, object: nil)
//                }
//            }
        }
        
        // Delete the episode from CoreData and the disk, and update the UI
        if let fileName = episode.fileName {
            PVDeleter
                .deleteEpisodeFromDiskWithName(fileName: fileName)
            episode.fileName = nil
        }
        
        // If the episode or a clip from the episode is currently a playlistItem in a local playlist, then do not delete the episode item from Core Data
        if checkIfEpisodeShouldBeRemoved(episode) == true {
            CoreDataHelper.deleteItemFromCoreData(deleteObjectID: episode.objectID, moc: moc)
        }
        
        moc.saveData(nil)
    }
    
    static func checkIfEpisodeShouldBeRemoved(_ episode: Episode) -> Bool {
        let moc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        moc.parent = CoreDataHelper.shared.managedObjectContext
        
        var alsoDelete = true
        
        if episode.podcast.isSubscribed == true || episode.podcast.isFollowed == true {
            alsoDelete = false
            return alsoDelete
        }
        
        if let allPlaylists = CoreDataHelper.fetchEntities(className: "Playlist", predicate: nil, moc: moc) as? [Playlist] {
            outerLoop: for playlist in allPlaylists {
                for item in playlist.allItems {
                    if let episode = item as? Episode {
                        for ep in episode.podcast.episodes {
                            if ep.objectID == episode.objectID {
                                alsoDelete = false
                                break outerLoop
                            }
                        }
                    }
                    else if let clip = item as? Clip {
                        for ep in episode.podcast.episodes {
                            for cl in ep.clips {
                                if clip.objectID == cl.objectID {
                                    alsoDelete = false
                                    break outerLoop
                                }
                            }
                        }
                    }
                }
            }
        }
        
        return alsoDelete
    }
    
    static func deleteEpisodeFromDiskWithName(fileName:String) {
        let URLs = FileManager().urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask)
        if let destinationURL = URLs.first?.appendingPathComponent(fileName) {
            do {
                try FileManager().removeItem(at:destinationURL)
            } catch {
                print("Item does not exist on disk")
            }
        }
    }
}
