//
//  PVSubscriber.swift
//  Podverse
//
//  Created by Mitchell Downey on 5/6/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

import UIKit
import CoreData

class PVSubscriber {
    
    static func subscribeToPodcast(feedUrlString: String, podcastTableDelegate:PodcastsTableViewController?) {
        ParsingPodcastsList.shared.urls.append(feedUrlString)
        if let ptd = podcastTableDelegate {
            ptd.updateParsingActivity()
        }

        feedParsingQueue.async() {
            let feedParser = PVFeedParser(shouldOnlyGetMostRecentEpisode: false, shouldSubscribe: true, shouldFollowPodcast: false, shouldOnlyParseChannel: false)
            feedParser.delegate = podcastTableDelegate
            feedParser.parsePodcastFeed(feedUrlString: feedUrlString)
        }
    }
//
//    static func unsubscribeFromPodcast(podcastID:NSManagedObjectID, completionBlock:(()->Void)?) {
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
//            let moc = CoreDataHelper.sharedInstance.backgroundContext
//            let podcast = CoreDataHelper.fetchEntityWithID(podcastID, moc: moc) as! Podcast
//            let alsoDelete = PVDeleter.checkIfPodcastShouldBeRemoved(podcast, isUnsubscribing: true, isUnfollowing: false, moc:moc)
//            podcast.isSubscribed = false
//            
//            CoreDataHelper.saveCoreData(moc, completionBlock: { completed in
//                if alsoDelete {
//                    PVDeleter.deletePodcast(podcast.objectID, completionBlock: {
//                        completionBlock?()
//                    })
//                }
//                else {
//                    let episodesToRemove = podcast.episodes.allObjects as! [Episode]
//                    // Delete each episode from the moc, cancel current downloadTask, and remove episode from the episodeDownloadArray
//                    for episode in episodesToRemove {
//                        let episodeToRemove = CoreDataHelper.fetchEntityWithID(episode.objectID, moc: moc) as! Episode
//                        PVDeleter.deleteEpisode(episodeToRemove.objectID)
//                    }
//                    completionBlock?()
//                }
//            })
//        }
//    }
    
}
