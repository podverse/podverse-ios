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

extension Notification.Name {
    static let episodeDeleted = Notification.Name("episodeDeleted")
    static let podcastDeleted = Notification.Name("podcastDeleted")
}

class PVDeleter {
    
    static func deletePodcast(podcastId: NSManagedObjectID?, feedUrl: String? = nil) {
        let moc = CoreDataHelper.createMOCForThread(threadType: .privateThread)
        
        if let podcastId = podcastId, let podcast = CoreDataHelper.fetchEntityWithID(objectId: podcastId, moc: moc) as? Podcast {
            deleteAllEpisodesFromPodcast(podcast: podcast)
            moc.delete(podcast)
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .podcastDeleted, object: nil, userInfo: ["feedUrl": podcast.feedUrl as? Any])
            }
        } else if let feedUrl = feedUrl, let podcast = Podcast.podcastForFeedUrl(feedUrlString: feedUrl, managedObjectContext: moc) {
            deleteAllEpisodesFromPodcast(podcast: podcast)
            moc.delete(podcast)
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .podcastDeleted, object: nil, userInfo: ["feedUrl": feedUrl as? Any])
            }
        }
        
        moc.saveData(nil)
    }
    
    static func deleteAllEpisodesFromPodcast(podcast: Podcast) {
        let episodesToRemove = podcast.episodes
        for episode in episodesToRemove {
            PVDeleter.deleteEpisode(episodeId: episode.objectID)
        }
    }
    
    static func deleteEpisode(episodeId: NSManagedObjectID, fileOnly: Bool = false, shouldCallNotificationMethod: Bool = false) {
        DispatchQueue.global().async {
            let moc = CoreDataHelper.createMOCForThread(threadType: .privateThread)
            
            if let episode = CoreDataHelper.fetchEntityWithID(objectId: episodeId, moc: moc) as? Episode {
                let podcastFeedUrl = episode.podcast.feedUrl
                let mediaUrl = episode.mediaUrl
                let downloadSession = PVDownloader.shared.downloadSession
                downloadSession?.getTasksWithCompletionHandler { dataTasks, uploadTasks, downloadTasks in
                    for downloadTask in downloadTasks {
                        if let _ = DownloadingEpisodeList.shared.downloadingEpisodes.first(where:{ $0.taskIdentifier == downloadTask.taskIdentifier && $0.podcastFeedUrl == podcastFeedUrl}) {
                            downloadTask.cancel()
                        }
                    }
                    
                }
                
                DownloadingEpisodeList.removeDownloadingEpisodeWithMediaURL(mediaUrl: mediaUrl)
                
                if let currentlyPlayingItem = PVMediaPlayer.shared.currentlyPlayingItem {
                    if mediaUrl == currentlyPlayingItem.episodeMediaUrl {
                        PVMediaPlayer.shared.avPlayer.pause()
                        PVMediaPlayer.shared.currentlyPlayingItem = nil
                    }
                }
                
                if let fileName = episode.fileName {
                    PVDeleter.deleteEpisodeFromDiskWithName(fileName: fileName)
                    episode.fileName = nil
                }
                
                if fileOnly == false {
                    CoreDataHelper.deleteItemFromCoreData(deleteObjectID: episode.objectID, moc: moc)
                }
                
                moc.saveData(nil)
                
                DispatchQueue.main.async {
                    PVDownloader.shared.decrementBadge()
                    
                    if shouldCallNotificationMethod == true {
                        NotificationCenter.default.post(name: .episodeDeleted, object: nil, userInfo: ["mediaUrl":mediaUrl as? Any])
                    }
                }
            }
            
        }

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
