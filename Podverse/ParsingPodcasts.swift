//
//  ParsingPodcastUrls.swift
//  Podverse
//
//  Created by Mitchell Downey on 9/19/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

import Foundation

final class ParsingPodcasts {
    static let shared = ParsingPodcasts()
    var urls = [String]()
    var currentlyParsingItem = 0
    
    func clearParsingPodcastsIfFinished() {
        if currentlyParsingItem == urls.count {
            currentlyParsingItem = 0
            self.urls.removeAll()
            NotificationCenter.default.post(name:NSNotification.Name(rawValue: kFinishedAllParsingPodcasts), object: self, userInfo: nil)
        }
    }
    
    func addPodcast(feedUrl:String) {
        if self.urls.filter({$0 == feedUrl}).count < 1 {
            self.urls.append(feedUrl)
            NotificationCenter.default.post(name:NSNotification.Name(rawValue: kBeginParsingPodcast), object: self, userInfo: nil)
        }
    }
    
    func removePodcast(feedUrl:String) {
        if let index = self.urls.index(of: feedUrl) {
            self.urls.remove(at: index)
            NotificationCenter.default.post(name:NSNotification.Name(rawValue: kBeginParsingPodcast), object: self, userInfo: nil)
        }
    }
    
    func hasMatchingUrl(feedUrl:String) -> Bool {
        if let _ = self.urls.index(of: feedUrl) {
            return true
        }
        
        return false
    }
    
    func podcastFinishedParsing() {
        self.currentlyParsingItem += 1
        NotificationCenter.default.post(name:NSNotification.Name(rawValue: kFinishedParsingPodcast), object: self, userInfo: nil)
        clearParsingPodcastsIfFinished()
    }
        
}
