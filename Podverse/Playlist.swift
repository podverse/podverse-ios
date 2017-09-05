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
    var dateCreated: Date?
    var lastUpdated: Date?
    var isMyClips: Bool = false
    var mediaRefs = [MediaRef]()
    
    static func jsonToPlaylist(item: [String:Any]) -> Playlist {
    
        let playlist = Playlist()
        
        playlist.id = item["id"] as? String
        playlist.isMyClips = item["isMyClips"] as? Bool ?? false
        playlist.slug = item["slug"] as? String
        playlist.title = item["title"] as? String
        playlist.ownerId = item["ownerId"] as? String
        playlist.ownerName = item["ownerName"] as? String
        
        if let lastUpdated = item["lastUpdated"] as? String {
            playlist.lastUpdated = lastUpdated.toServerDate()
        }
        
        if let dateCreated = item["dateCreated"] as? String {
            playlist.dateCreated = dateCreated.toServerDate()
        }
        
        if let mediaRefsJSON = item["mediaRefs"] as? [[String:Any]] {
            for item in mediaRefsJSON {
                let mediaRef = MediaRef.jsonToMediaRef(item: item)
                playlist.mediaRefs.append(mediaRef)
            }
        }
    
        return playlist
    
    }
    
    static func retrievePlaylistFromServer(id: String, completion: @escaping (_ playlist: Playlist?) -> Void) {
        
        if let url = URL(string: BASE_URL + "playlist") {
            var request = URLRequest(url: url, cachePolicy: NSURLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 60)
            
            request.httpMethod = "POST"
            
            let postString = "id=" + id
            
            request.httpBody = postString.data(using: .utf8)
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                
                guard error == nil else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }
                
                if let data = data {
                    do {
                        let playlist: Playlist?
                        
                        if let item = try JSONSerialization.jsonObject(with: data, options: []) as? [String:Any] {
                            playlist = jsonToPlaylist(item: item)
                            
                            DispatchQueue.main.async {
                                completion(playlist)
                            }
                        }
                        
                    } catch {
                        print(error.localizedDescription)
                        print("Error")
                    }
                }
                
            }
            
            task.resume()
            
        }
        
    }
    
    static func retrievePlaylistsFromServer(completion: @escaping (_ playlists: [Playlist]?) -> Void) {
        
        if let url = URL(string: BASE_URL + "user/playlists") {
            var request = URLRequest(url: url, cachePolicy: NSURLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 60)
            request.httpMethod = "POST"
            
            if let idToken = UserDefaults.standard.string(forKey: "idToken") {
                request.setValue(idToken, forHTTPHeaderField: "authorization")
            }
            
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                
                guard error == nil else {
                    DispatchQueue.main.async {
                        completion([])
                    }
                    return
                }
                
                if let data = data {
                    do {
                        var playlists = [Playlist]()
                        
                        if let playlistsJSON = try JSONSerialization.jsonObject(with: data, options: []) as? [[String:Any]] {
                            
                            for item in playlistsJSON {
                                let playlist = jsonToPlaylist(item: item)
                                playlists.append(playlist)
                            }
                            
                        }
                        
                        DispatchQueue.main.async {
                            completion(playlists)
                        }
                        
                    } catch {
                        print(error.localizedDescription)
                        print("Error")
                    }
                }
                
                
                
            }
            
            task.resume()
            
        }
        
    }
    
}
