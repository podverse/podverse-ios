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
    var podcastKeys = [String]()
    var currentlyParsingItem = 0
    
    func clearParsingPodcastsIfFinished() {
        if currentlyParsingItem == podcastKeys.count {
            currentlyParsingItem = 0
            self.podcastKeys.removeAll()
            DispatchQueue.main.async {
                NotificationCenter.default.post(name:NSNotification.Name(rawValue: kFinishedAllParsingPodcasts), object: self, userInfo: nil)
            }
        }
    }
    
    func addPodcast(podcastId:String?, feedUrl:String?) {
        if let podcastId = podcastId, self.podcastKeys.filter({$0 == podcastId}).count < 1 {
            self.podcastKeys.append(podcastId)
            DispatchQueue.main.async {
                NotificationCenter.default.post(name:NSNotification.Name(rawValue: kBeginParsingPodcast), object: self, userInfo: nil)
            }
        } else if let feedUrl = feedUrl, self.podcastKeys.filter({$0 == feedUrl}).count < 1, podcastId == nil {
            self.podcastKeys.append(feedUrl)
            DispatchQueue.main.async {
                NotificationCenter.default.post(name:NSNotification.Name(rawValue: kBeginParsingPodcast), object: self, userInfo: nil)
            }
        }
    }
    
    func removePodcast(podcastId:String?, feedUrl:String?) {
        if let podcastId = podcastId, let index = self.podcastKeys.index(of: podcastId) {
            self.podcastKeys.remove(at: index)
            DispatchQueue.main.async {
                NotificationCenter.default.post(name:NSNotification.Name(rawValue: kFinishedParsingPodcast), object: self, userInfo: nil)
            }
        } else if let feedUrl = feedUrl, let index = self.podcastKeys.index(of: feedUrl) {
            self.podcastKeys.remove(at: index)
            DispatchQueue.main.async {
                NotificationCenter.default.post(name:NSNotification.Name(rawValue: kFinishedParsingPodcast), object: self, userInfo: nil)
            }
        }
    }

    func hasMatchingId(podcastId:String?) -> Bool {
        if let podcastId = podcastId, let _ = self.podcastKeys.index(of: podcastId) {
            return true
        }
        
        return false
    }
    
    func hasMatchingUrl(feedUrl:String) -> Bool {
        if let _ = self.podcastKeys.index(of: feedUrl) {
            return true
        }
        
        return false
    }
    
    func podcastFinishedParsing() {
        self.currentlyParsingItem += 1
        clearParsingPodcastsIfFinished()
        DispatchQueue.main.async {
            NotificationCenter.default.post(name:NSNotification.Name(rawValue: kFinishedParsingPodcast), object: self, userInfo: nil)
        }
    }
        
}
