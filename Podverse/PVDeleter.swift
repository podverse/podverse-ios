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

class PVDeleter: NSObject {
    
    static func deletePodcast(podcastId: NSManagedObjectID?, feedUrl: String? = nil) {
            let moc = CoreDataHelper.createMOCForThread(threadType: .mainThread)

            var podcastToDelete:Podcast!
            
            if let podcastId = podcastId, let podcast = CoreDataHelper.fetchEntityWithID(objectId: podcastId, moc: moc) as? Podcast {
                podcastToDelete = podcast
            } else if let feedUrl = feedUrl, let podcast = Podcast.podcastForFeedUrl(feedUrlString: feedUrl, managedObjectContext: moc) {
                podcastToDelete = podcast
            }
            else {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(  name: .podcastDeleted, 
                                                    object: nil, 
                                                  userInfo: ["feedUrl": feedUrl ?? ""])
                }
                return
            }
            
            podcastToDelete.removeFromAutoDownloadList()
            deleteAllEpisodesFromPodcast(podcastId: podcastToDelete.objectID)
            moc.delete(podcastToDelete)
            
            moc.saveData({ 
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .podcastDeleted, object: nil, userInfo: ["feedUrl": feedUrl ?? ""])
                }
            })
    }
    
    static func deleteAllEpisodesFromPodcast(podcastId: NSManagedObjectID) {        
        DispatchQueue.global().async {
            let moc = CoreDataHelper.createMOCForThread(threadType: .privateThread)
            if let podcast = CoreDataHelper.fetchEntityWithID(objectId: podcastId, moc: moc) as? Podcast {
                let episodesToRemove = podcast.episodes
                for episode in episodesToRemove {
                    PVDeleter.deleteEpisode(episodeId: episode.objectID, moc:moc)
                }
            }
        }
    }
    
    static func deleteEpisode(episodeId: NSManagedObjectID, fileOnly: Bool = false, shouldCallNotificationMethod: Bool = false, moc:NSManagedObjectContext? = nil) {
        
        let pvMediaPlayer = PVMediaPlayer.shared
        let moc = moc ?? CoreDataHelper.createMOCForThread(threadType: .mainThread)
        
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
            
            if let nowPlayingItem = pvMediaPlayer.nowPlayingItem {
                if mediaUrl == nowPlayingItem.episodeMediaUrl {
                    pvMediaPlayer.audioPlayer.pause()
                    pvMediaPlayer.nowPlayingItem = nil
                }
            }
            
            if let fileName = episode.fileName {
                PVDeleter.deleteEpisodeFromDiskWithName(fileName: fileName)
                episode.fileName = nil
            }
            
            if fileOnly == false {
                moc.delete(episode)
            }
            
            if let nowPlayingItem = PlayerHistory.manager.historyItems.first {
                nowPlayingItem.hasReachedEnd = true
                PlayerHistory.manager.addOrUpdateItem(item: nowPlayingItem)
            }
            
            moc.saveData() {
                DispatchQueue.main.async {
                    PVDownloader.shared.decrementBadge()
                    
                    if shouldCallNotificationMethod == true {
                        NotificationCenter.default.post(name: .episodeDeleted, object: nil, userInfo: ["mediaUrl":mediaUrl ?? ""])
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
