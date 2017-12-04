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
    
    static func deletePodcast(feedUrl: String? = nil) {
        
        DispatchQueue.global().async {
            let privateMoc = CoreDataHelper.createMOCForThread(threadType: .privateThread)
            
            guard let feedUrl = feedUrl, let podcastToDelete = Podcast.podcastForFeedUrl(feedUrlString: feedUrl, managedObjectContext: privateMoc) else {
                return
            }
            
            if DeletingPodcasts.shared.hasMatchingUrl(feedUrl: feedUrl) {
                return
            }
            
            DeletingPodcasts.shared.addPodcast(feedUrl: feedUrl)
            ParsingPodcasts.shared.removePodcast(feedUrl: feedUrl)
            podcastToDelete.removeFromAutoDownloadList()
            deleteAllEpisodesFromPodcast(feedUrl: feedUrl)
            privateMoc.delete(podcastToDelete)
            privateMoc.saveData({
                DeletingPodcasts.shared.removePodcast(feedUrl: feedUrl)
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .podcastDeleted, object: nil, userInfo: ["feedUrl": feedUrl ?? ""])
                }
            })
            
        }
        
    }
    
    static func deleteAllEpisodesFromPodcast(feedUrl: String) {
        
        DispatchQueue.global().async {
            let privateMoc = CoreDataHelper.createMOCForThread(threadType: .privateThread)
            
            if let podcast = Podcast.podcastForFeedUrl(feedUrlString: feedUrl, managedObjectContext: privateMoc) {
                let episodesToRemove = podcast.episodes
                for episode in episodesToRemove {
                    PVDeleter.deleteEpisode(mediaUrl: episode.mediaUrl)
                }
            }
        }
        
    }
    
    static func deleteEpisode(mediaUrl: String?, fileOnly: Bool = false, shouldCallNotificationMethod: Bool = false) {
        
        DispatchQueue.global().async {
            
            let privateMoc = CoreDataHelper.createMOCForThread(threadType: .privateThread)
            
            let pvMediaPlayer = PVMediaPlayer.shared
            
            if let mediaUrl = mediaUrl {
                
                if let episode = Episode.episodeForMediaUrl(mediaUrlString: mediaUrl, managedObjectContext: privateMoc) {
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
                        privateMoc.delete(episode)
                    }
                    
                    if let nowPlayingItem = PlayerHistory.manager.historyItems.first {
                        nowPlayingItem.hasReachedEnd = true
                        PlayerHistory.manager.addOrUpdateItem(item: nowPlayingItem)
                    }
                    
                    privateMoc.saveData() {
                        if shouldCallNotificationMethod == true {
                            DispatchQueue.main.async {
                                NotificationCenter.default.post(name: .episodeDeleted, object: nil, userInfo: ["mediaUrl":mediaUrl ?? ""])
                            }
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
