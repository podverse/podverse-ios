//
//  Playlist.swift
//  Podverse
//
//  Created by Creon on 12/24/16.
//  Copyright © 2016 Podverse LLC. All rights reserved.
//

import Foundation
import CoreData

class Playlist {
    
    var id: String?
    var title: String?
    var slug: String?
    var ownerId: String?
    var ownerName: String?
    var dateCreated: String?
    var lastUpdated: String?
    var isMyClips: Bool = false
    
    static func retrievePlaylistsFromServer() {
        
        if let url = URL(string: "https://podverse.fm/api/user/playlists") {
            var request = URLRequest(url: url, cachePolicy: NSURLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 60)
            request.httpMethod = "POST"
            
            if let idToken = UserDefaults.standard.string(forKey: "idToken") {
                request.setValue(idToken, forHTTPHeaderField: "authorization")
            }
            
            
        }
        
    }
    
}
