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
    
    static func subscribeToPodcast(feedUrlString: String?) {
        
        if let feedUrlString = feedUrlString {
            feedParsingQueue.async() {
                let feedParser = PVFeedParser(shouldOnlyGetMostRecentEpisode: false, shouldSubscribe: true, shouldOnlyParseChannel: false)
                DispatchQueue.main.async {
                    feedParser.delegate = ((UIApplication.shared.keyWindow?.rootViewController as? UITabBarController)?.viewControllers?.first as? UINavigationController)?.topViewController as? PodcastsTableViewController
                }
                feedParser.parsePodcastFeed(feedUrlString: feedUrlString)
            }
        }
        
    }
    
    static func checkIfSubscribed(feedUrlString: String?) -> Bool {
        if let feedUrlString = feedUrlString, let _ = Podcast.podcastForFeedUrl(feedUrlString: feedUrlString) {
            return true
        } else {
            return false
        }
    }
    
}
