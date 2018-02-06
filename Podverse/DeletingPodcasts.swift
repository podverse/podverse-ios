//
//  DeletingPodcasts.swift
//  Podverse
//
//  Created by Mitchell Downey on 11/19/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

import Foundation

final class DeletingPodcasts {
    static let shared = DeletingPodcasts()
    var podcastKeys = [String]()
    
    func addPodcast(podcastId:String?, feedUrl:String?) {
        if let podcastId = podcastId {
            if self.podcastKeys.filter({$0 == podcastId}).count < 1 {
                self.podcastKeys.append(podcastId)
            }
        } else if let feedUrl = feedUrl {
            if self.podcastKeys.filter({$0 == feedUrl}).count < 1 {
                self.podcastKeys.append(feedUrl)
            }
        }
    }
    
    func removePodcast(podcastId:String?, feedUrl:String?) {
        if let podcastId = podcastId, let index = self.podcastKeys.index(of: podcastId) {
            self.podcastKeys.remove(at: index)
        } else if let feedUrl = feedUrl, let index = self.podcastKeys.index(of: feedUrl) {
            self.podcastKeys.remove(at: index)
        }
    }
    
    func hasMatchingId(podcastId:String) -> Bool {
        if let _ = self.podcastKeys.index(of: podcastId) {
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
    
}
