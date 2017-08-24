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
    
    // TODO: how do we save [MediaRef] as a property?
    
    static func retrievePlaylistsFromServer(completion: @escaping (_ playlists:[Playlist]?) -> Void) {
        
        if let url = URL(string: "http://localhost:8080/api/user/playlists") {
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
                        
                        if let responseJSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String:Any] {
                            
                            if let playlistsJSON = responseJSON["data"] as? [[String:Any]] {
                                
                                for item in playlistsJSON {
                                    let playlist = Playlist()
                                    playlist.title = item["title"] as? String
                                    playlist.slug = item["slug"] as? String

                                    playlist.isMyClips = item["isMyClips"] as? Bool ?? false
                                    playlist.id = item["id"] as? String
                                    playlist.ownerId = item["ownerId"] as? String
                                    playlist.ownerName = item["ownerName"] as? String
                                    
                                    if let lastUpdated = item["lastUpdated"] as? String {
                                        playlist.lastUpdated = lastUpdated.toServerDate()
                                    }
                                    
                                    if let dateCreated = item["dateCreated"] as? String {
                                        playlist.dateCreated = dateCreated.toServerDate()
                                    }
                                    
                                    playlists.append(playlist)
                                }
                                
                            }
                            
                        }
                        
                        DispatchQueue.main.async {
                            completion(playlists)
                        }
                        
                    } catch {
                        print(error)
                        print("Error")
                    }
                }
                
                
                
            }
            
            task.resume()
            
        }
        
    }
    
}
