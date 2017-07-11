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
    
    static func subscribeToPodcast(feedUrlString: String) {
        feedParsingQueue.async() {
            let feedParser = PVFeedParser(shouldOnlyGetMostRecentEpisode: false, shouldSubscribe: true, shouldFollowPodcast: false, shouldOnlyParseChannel: false)
            feedParser.parsePodcastFeed(feedUrlString: feedUrlString)
        }
    }
    
}
