
//
//  Podcast.swift
//  Podverse
//
//  Created by Creon on 12/24/16.
//  Copyright © 2016 Podverse LLC. All rights reserved.
//

import Foundation
import CoreData
import SDWebImage
import UIKit

class Podcast: NSManagedObject {
    @NSManaged public var author: String?
    @NSManaged public var categories: String?
    @NSManaged public var episodes: Set<Episode>
    @NSManaged public var feedUrl: String
    @NSManaged public var imageData: Data?
    @NSManaged public var imageThumbData: Data?
    @NSManaged public var imageThumbUrl: String?
    @NSManaged public var imageUrl: String?
    @NSManaged public var itunesImage: Data?
    @NSManaged public var itunesImageUrl: String?
    @NSManaged public var lastBuildDate: Date?
    @NSManaged public var lastPubDate: Date?
    @NSManaged public var link: String? // generally the home page
    @NSManaged public var id: String? // the id of the podcast on the official server
    @NSManaged public var summary: String?
    @NSManaged public var title: String
    
    func addEpisodeObject(value: Episode) {
        self.mutableSetValue(forKey: "episodes").add(value)
    }
    
    func removeEpisodeObject(value: Episode) {
        self.mutableSetValue(forKey: "episodes").remove(value)
    }
    
    static func podcastForFeedUrl(feedUrlString: String, managedObjectContext:NSManagedObjectContext? = nil) -> Podcast? {
        let moc = managedObjectContext ?? CoreDataHelper.createMOCForThread(threadType: .mainThread)

        let predicate = NSPredicate(format: "feedUrl == %@", feedUrlString)
        let podcastSet = CoreDataHelper.fetchEntities(className: "Podcast", predicate: predicate, moc:moc) as? [Podcast]
        
        return podcastSet?.first
    }
        
    static func podcastForId(id: String, managedObjectContext:NSManagedObjectContext? = nil) -> Podcast? {
        let moc = managedObjectContext ?? CoreDataHelper.createMOCForThread(threadType: .mainThread)
        
        let predicate = NSPredicate(format: "id == %@", id)
        let podcastSet = CoreDataHelper.fetchEntities(className: "Podcast", predicate: predicate, moc:moc) as? [Podcast]
        
        return podcastSet?.first
    }
    
    func shouldAutoDownload() -> Bool {
        if let autoDownloadingFeedUrls = UserDefaults.standard.array(forKey: kAutoDownloadingFeedUrls) as? [String] {
            if autoDownloadingFeedUrls.contains(self.feedUrl) {
                return true
            } else {
                return false
            }
        }
        
        return false
    }
    
    func addToAutoDownloadList() {
        
        if var autoDownloadingFeedUrls = UserDefaults.standard.array(forKey: kAutoDownloadingFeedUrls) as? [String] {
            if !autoDownloadingFeedUrls.contains(self.feedUrl) {
                autoDownloadingFeedUrls.append(self.feedUrl)
                UserDefaults.standard.setValue(autoDownloadingFeedUrls, forKey: kAutoDownloadingFeedUrls)
            }
        } else {
            UserDefaults.standard.setValue([self.feedUrl], forKey: kAutoDownloadingFeedUrls)
        }
        
    }
    
    func removeFromAutoDownloadList() {
        if let autoDownloadingFeedUrls = UserDefaults.standard.array(forKey: kAutoDownloadingFeedUrls) as? [String] {
            let results = autoDownloadingFeedUrls.filter { $0 != self.feedUrl}
            UserDefaults.standard.setValue(results, forKey: kAutoDownloadingFeedUrls)
        }
    }
    
    static func retrieveSubscribedUrls() -> [String] {
        let moc = CoreDataHelper.createMOCForThread(threadType: .privateThread)
        var subscribedPodcastFeedUrls = [String]()
        let subscribedPodcastsArray = CoreDataHelper.fetchEntities(className:"Podcast", predicate: nil, moc:moc) as! [Podcast]
        
        for podcast in subscribedPodcastsArray {
            subscribedPodcastFeedUrls.append(podcast.feedUrl)
        }
        
        return subscribedPodcastFeedUrls
    }
    
    /**
     Retrieves the image of a specific Podcast channel. This method takes 4 optional arguements and returns
     the image related to the podcast tied with one of the first three parameters.
     NOTE: This method can set the podcast image directly only if the arguments used DO NOT include the
     `podcastImageURLString` parameter. If this parameter is used, the call is asychronous and the completion closure must be used to set the returned image. Everything is dispatched to the main queue in the completion closure.
     
     - Parameters:
     - podcastImageURLString: A string with the url of the podcastImageUrl
     - feedURLString: A string with the feedURL of the podcast
     - managedObjectID: The managed object id of the podcast
     - completion: A completion block for the async functionality of fetchng the image from a url
     
     - Returns: The podcast image that was fetched (Discardable)
     */
    @discardableResult static func retrievePodcastImage(podcastImageURLString:String? = nil, feedURLString:String? = nil, completion:((_ podcastImage: UIImage) -> Void)? = nil) -> UIImage {
                
        if let feedUrl = feedURLString, !feedUrl.isEmpty, let podcastImage = Podcast.fetchPodcastImage(podcastFeedUrl: feedUrl) {
            return podcastImage
        }
        
        if let imageURLString = podcastImageURLString, let url = URL(string:imageURLString) {
            Podcast.fetchPodcastImage(podcastImageUrl: url, completion: { (image) in
                DispatchQueue.main.async {
                    completion?(image)
                }
            })
        }
        
        return UIImage(named: "PodverseIcon")!
    }
    
    private static func fetchPodcastImage(podcastFeedUrl: String) -> UIImage? {
        let moc = CoreDataHelper.createMOCForThread(threadType: .mainThread)
        
        let predicate = NSPredicate(format: "feedUrl == %@", podcastFeedUrl)
        if let podcastSet = CoreDataHelper.fetchEntities(className: "Podcast", predicate: predicate, moc:moc) as? [Podcast], let imageData = podcastSet.first?.imageData, let image = UIImage(data:imageData) {
            return image
        }
        
        return nil
    }
    
    private static func fetchPodcastImage(podcastImageUrl: URL, completion: @escaping (_ podcastImage: UIImage) -> Void) {
        
        SDWebImageManager.shared().loadImage(with: podcastImageUrl, options: SDWebImageOptions.highPriority, progress: nil) { (image, _, _, _ , _ , _) in
            var downloadedImage = UIImage(named: "PodverseIcon")!
            
            if let image = image {
                downloadedImage = image
            }
            
            completion(downloadedImage)
        }
    }
    
    static func syncSubscribedPodcastsWithServer() {
        
        // Only podcasts that have an id will sync with the server. If a user manually adds a podcast by RSS feed locally to the app, it will not be saved to the server.
        retrieveSubscribedPodcastsFromServer() { syncPodcasts in
            
            guard let syncPodcasts = syncPodcasts, syncPodcasts.count > 0 else {
                NotificationCenter.default.post(name: .feedParsingComplete, object: nil, userInfo: nil)
                return
            }
            
            for syncPodcast in syncPodcasts {
                if let feedUrl = syncPodcast.feedUrl {
                    let pvFeedParser = PVFeedParser(shouldOnlyGetMostRecentEpisode: true, shouldSubscribe: false, podcastId: syncPodcast.id)
                    pvFeedParser.parsePodcastFeed(feedUrlString: feedUrl)
                }
            }

        }
        
    }
        
    // TODO: This end point should be optimized better.
    static func retrieveSubscribedPodcastsFromServer(completion: @escaping (_ syncPodcasts: [SyncablePodcast]?) -> Void) {
        
        if let url = URL(string: BASE_URL + "api/user/podcasts") {
            var request = URLRequest(url: url, cachePolicy: NSURLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 60)
            request.httpMethod = "POST"
            
            guard let idToken = UserDefaults.standard.string(forKey: "idToken") else {
                DispatchQueue.main.async {
                    completion([])
                }
                return
            }
            
            request.setValue(idToken, forHTTPHeaderField: "authorization")
            
            let task = URLSession.shared.dataTask(with: request) { userData, response, error in
                
                guard error == nil else {
                    DispatchQueue.main.async {
                        completion([])
                    }
                    return
                }
                
                if let userData = userData {
                    do {
                        var syncPodcasts = [SyncablePodcast]()
                        
                        if let userDataJSON = try JSONSerialization.jsonObject(with: userData, options: []) as? [String:Any] {
                            
                            if let subscribedPodcasts = userDataJSON["subscribedPodcasts"] as? [[String:Any]] {

                                for subscribedPodcast in subscribedPodcasts {
                                    let syncPodcast = SyncablePodcast()
                                    
                                    if let feedUrl = subscribedPodcast["authorityFeedUrl"] as? String {
                                        syncPodcast.feedUrl = feedUrl
                                    }
                                    
                                    if let id = subscribedPodcast["id"] as? String {
                                        syncPodcast.id = id
                                    }
                                    
                                    syncPodcasts.append(syncPodcast)
                                }
                            }
                            
                        }
                        
                        DispatchQueue.main.async {
                            completion(syncPodcasts)
                        }
                        
                    } catch {
                        print("Error: " + error.localizedDescription)
                        DispatchQueue.main.async {
                            completion([])
                        }
                    }
                }
                
            }
            
            task.resume()
            
        }
    }
    
}
