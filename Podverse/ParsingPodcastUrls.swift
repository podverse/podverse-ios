//
//  ParsingPodcastUrls.swift
//  Podverse
//
//  Created by Mitchell Downey on 9/19/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

import Foundation

final class ParsingPodcastsList {
    static let shared = ParsingPodcastsList()
    var urls = [String]()
    var currentlyParsingItem = 0
    
    func clearParsingPodcastsIfFinished() {
        if currentlyParsingItem == urls.count {
            currentlyParsingItem = 0
            urls.removeAll()
            NotificationCenter.default.post(name:NSNotification.Name(rawValue: kFinishedAllParsingPodcasts), object: self, userInfo: nil)
        }
    }
    
    func addPodcast(feedUrl: String) {
        urls.append(feedUrl)
        NotificationCenter.default.post(name:NSNotification.Name(rawValue: kBeginParsingPodcast), object: self, userInfo: nil)
    }
    
    func podcastFinishedParsing() {
        self.currentlyParsingItem += 1
        NotificationCenter.default.post(name:NSNotification.Name(rawValue: kFinishedParsingPodcast), object: self, userInfo: nil)
        clearParsingPodcastsIfFinished()
    }
        
}
