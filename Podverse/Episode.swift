//
//  Episode.swift
//  Podverse
//
//  Created by Creon on 12/24/16.
//  Copyright © 2016 Podverse LLC. All rights reserved.
//

import Foundation
import CoreData

class Episode: NSManagedObject {
    @NSManaged var duration: NSNumber?
    @NSManaged var fileName: String?
    @NSManaged var guid: String?
    @NSManaged var link: String?
    @NSManaged var mediaBytes: NSNumber?
    @NSManaged var mediaType: String?
    @NSManaged var mediaUrl: String?
    @NSManaged var pubDate: Date?
    @NSManaged var summary: String?
    @NSManaged var title: String?
    @NSManaged var uuid: String?
    @NSManaged var podcast: Podcast
    
    static func episodeForMediaUrl(mediaUrlString: String, managedObjectContext:NSManagedObjectContext? = nil) -> Episode? {
        let moc = managedObjectContext ?? CoreDataHelper.createMOCForThread(threadType: .mainThread)
        
        let predicate = NSPredicate(format: "mediaUrl == %@", mediaUrlString)
        let episodeSet = CoreDataHelper.fetchEntities(className: "Episode", predicate: predicate, moc:moc) as? [Episode]
        
        return episodeSet?.first
    }
    
    static func jsonToPlayerHistoryItem(json: [String:Any]) -> PlayerHistoryItem? {
        
        if let podcast = json["podcast"] as? [String:Any], let isPublic = json["isPublic"] as? Bool {
            let podcastId = podcast["id"] as? String
            let podcastTitle = podcast["title"] as? String
            let podcastImageUrl = podcast["imageUrl"] as? String
            
            let episodeDuration = json["duration"] as? Int64
            let episodeMediaUrl = json["mediaUrl"] as? String
            let episodeTitle = json["title"] as? String
            let episodeImageUrl = json["imageUrl"] as? String
            let episodeSummary = json["summary"] as? String
            let episodePubDate = (json["pubDate"] as? String)?.toServerDate()
            let episodeLastUpdated = (json["lastUpdated"] as? String)?.toServerDate()
            
            let item = PlayerHistoryItem(mediaRefId: nil, podcastId: podcastId, podcastFeedUrl: nil, podcastTitle: podcastTitle, podcastImageUrl: podcastImageUrl, episodeDuration: episodeDuration, episodeMediaUrl: episodeMediaUrl, episodeTitle: episodeTitle, episodeImageUrl: episodeImageUrl, episodeSummary: episodeSummary, episodePubDate: episodePubDate, startTime: nil, endTime: nil, clipTitle: nil, ownerName: nil, ownerId: nil, hasReachedEnd: false, lastPlaybackPosition: nil, lastUpdated: episodeLastUpdated, isPublic: isPublic)
            
            return item
        }
        
        return nil
    }
    
    static func retrieveEpisodeFromServer(id:String, completion: @escaping (_ playerHistoryItem:PlayerHistoryItem?) -> Void) {
        if let url = URL(string: BASE_URL + "api/episodes") {
            
            let request = NSMutableURLRequest(url: url, cachePolicy: NSURLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 60)
            
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            request.httpMethod = "POST"
            
            var values: [String: Any] = [:]
            values["id"] = id
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: values, options: [])
            } catch {
                print("Error: \(error.localizedDescription)")
            }
            
            let task = URLSession.shared.dataTask(with: request as URLRequest) { data, response, error in
                
                hideNetworkActivityIndicator()
                guard error == nil else {
                    print("Error: \(error?.localizedDescription ?? "Unknown Error")")
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }
                
                if let data = data {
                    do {
                        if let responseJSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String:Any] {
                            let item = jsonToPlayerHistoryItem(json: responseJSON)
                            DispatchQueue.main.async {
                                completion(item)
                            }
                        }
                    } catch {
                        print("Error: " + error.localizedDescription)
                    }
                }
            }
            
            task.resume()
            
        }
    }
        
    static let episodeKey = "episode"
    
}


