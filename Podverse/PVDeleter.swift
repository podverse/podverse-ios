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
    
    static func deletePodcast(podcastId:String?, feedUrl:String?) {
        
        DispatchQueue.global().async {
            let privateMoc = CoreDataHelper.createMOCForThread(threadType: .privateThread)
            let podcast:Podcast?
            
            if let podcastId = podcastId {
                
                if DeletingPodcasts.shared.hasMatchingId(podcastId: podcastId) {
                    return
                }
                
                podcast = Podcast.podcastForId(id: podcastId, managedObjectContext: privateMoc)
            } else if let feedUrl = feedUrl {
                
                if DeletingPodcasts.shared.hasMatchingUrl(feedUrl: feedUrl) {
                    return
                }
                
                podcast = Podcast.podcastForFeedUrl(feedUrlString: feedUrl, managedObjectContext: privateMoc)
            } else {
                return
            }

            if let podcast = podcast {
                DeletingPodcasts.shared.addPodcast(podcastId: podcast.id, feedUrl: podcast.feedUrl)
                ParsingPodcasts.shared.removePodcast(podcastId: podcast.id, feedUrl: podcast.feedUrl)
                podcast.removeFromAutoDownloadList()
                deleteAllEpisodesFromPodcast(podcastId: podcast.id, feedUrl: podcast.feedUrl)
                privateMoc.delete(podcast)
                privateMoc.saveData({
                    DeletingPodcasts.shared.removePodcast(podcastId: podcast.id, feedUrl: podcast.feedUrl)
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .podcastDeleted, object: nil, userInfo: ["podcastId": podcastId ?? "", "feedUrl": feedUrl ?? ""])
                    }
                })
            }
            
        }
        
    }
    
    static func deleteAllEpisodesFromPodcast(podcastId:String?, feedUrl: String?) {
        
        DispatchQueue.global().async {
            let privateMoc = CoreDataHelper.createMOCForThread(threadType: .privateThread)
            var podcast:Podcast? = nil
            
            if let podcastId = podcastId {
                podcast = Podcast.podcastForId(id: podcastId, managedObjectContext: privateMoc)
            } else if let feedUrl = feedUrl {
                podcast = Podcast.podcastForFeedUrl(feedUrlString: feedUrl, managedObjectContext: privateMoc)
            }
            
            if let p = podcast {
                let episodes = p.episodes
                for episode in episodes {
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
