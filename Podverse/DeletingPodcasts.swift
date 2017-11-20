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
    var urls = [String]()
    
    func addPodcast(feedUrl:String) {
        if self.urls.filter({$0 == feedUrl}).count < 1 {
            self.urls.append(feedUrl)
        }
    }
    
    func removePodcast(feedUrl:String) {
        if let index = self.urls.index(of: feedUrl) {
            self.urls.remove(at: index)
        }
    }
    
    func hasMatchingUrl(feedUrl:String) -> Bool {
        if let _ = self.urls.index(of: feedUrl) {
            return true
        }
        
        return false
    }
    
}
