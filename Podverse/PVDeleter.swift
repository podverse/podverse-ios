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
    
    static func deletePodcast(feedUrl: String? = nil, moc: NSManagedObjectContext) {
    
        var podcastToDelete:Podcast?
        
        if let feedUrl = feedUrl, let podcast = Podcast.podcastForFeedUrl(feedUrlString: feedUrl, managedObjectContext: moc) {
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
        
        if let podcast = podcastToDelete {
            podcast.removeFromAutoDownloadList()
            deleteAllEpisodesFromPodcast(feedUrl: podcast.feedUrl, moc: moc)
            moc.delete(podcast)
            moc.saveData({
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .podcastDeleted, object: nil, userInfo: ["feedUrl": feedUrl ?? ""])
                }
            })
        }
        
    }
    
    static func deleteAllEpisodesFromPodcast(feedUrl: String, moc: NSManagedObjectContext) {
        if let podcast = Podcast.podcastForFeedUrl(feedUrlString: feedUrl, managedObjectContext: moc) {
            let episodesToRemove = podcast.episodes
            for episode in episodesToRemove {
                PVDeleter.deleteEpisode(mediaUrl: episode.mediaUrl, moc: moc)
            }
        }
    }
    
    static func deleteEpisode(mediaUrl: String?, moc: NSManagedObjectContext, fileOnly: Bool = false, shouldCallNotificationMethod: Bool = false) {
        
        let pvMediaPlayer = PVMediaPlayer.shared
        
        if let mediaUrl = mediaUrl {
            
            if let episode = Episode.episodeForMediaUrl(mediaUrlString: mediaUrl, managedObjectContext: moc) {
                let podcastFeedUrl = episode.podcast.feedUrl
                let downloadSession = PVDownloader.shared.downloadSession
                downloadSession?.getTasksWithCompletionHandler { dataTasks, uploadTasks, downloadTasks in
                    for downloadTask in downloadTasks {
                        if let _ = DownloadingEpisodeList.shared.downloadingEpisodes.first(where:{ $0.taskIdentifier == downloadTask.taskIdentifier && $0.podcastFeedUrl == podcastFeedUrl}) {
                            downloadTask.cancel()
                        }
                    }
                }
                
                DownloadingEpisodeList.removeDownloadingEpisodeWithMediaURL(mediaUrl: mediaUrl)
                
                if let nowPlayingItem = pvMediaPlayer.nowPlayingItem, mediaUrl == nowPlayingItem.episodeMediaUrl {
                    pvMediaPlayer.audioPlayer.pause()
                    pvMediaPlayer.nowPlayingItem = nil
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
                        if shouldCallNotificationMethod == true {
                            NotificationCenter.default.post(name: .episodeDeleted, object: nil, userInfo: ["mediaUrl":mediaUrl ?? ""])
                        }
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
