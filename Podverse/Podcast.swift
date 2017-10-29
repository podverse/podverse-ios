
//
//  Podcast.swift
//  Podverse
//
//  Created by Creon on 12/24/16.
//  Copyright © 2016 Podverse LLC. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class Podcast: NSManagedObject {
    @NSManaged public var audiosearchId: NSNumber?
    @NSManaged public var author: String?
    @NSManaged public var categories: String?
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
    @NSManaged public var summary: String?
    @NSManaged public var title: String
    @NSManaged public var episodes: Set<Episode>
    
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
    @discardableResult static func retrievePodcastImage(podcastImageURLString:String? = nil, feedURLString:String? = nil, managedObjectID:NSManagedObjectID? = nil, completion:((_ podcastImage: UIImage?) -> Void)? = nil) -> UIImage? {
        
        if let moid = managedObjectID {
            let image = Podcast.fetchPodcastImage(managedObjectId: moid)
            return image
        }
        
        if let feedUrl = feedURLString, !feedUrl.isEmpty {
            if let image = Podcast.fetchPodcastImage(podcastFeedUrl: feedUrl) {
                return image
            }
        }
        
        if let _ = podcastImageURLString {
            DispatchQueue.main.async {
                completion?(nil)
            }
        }
        
        return UIImage(named: "PodverseIcon")
    }
    
    private static func fetchPodcastImage(managedObjectId: NSManagedObjectID) -> UIImage? {
        let moc = CoreDataHelper.createMOCForThread(threadType: .mainThread)
        
        if let podcast = CoreDataHelper.fetchEntityWithID(objectId: managedObjectId, moc: moc) as? Podcast,
            let imageData = podcast.imageData {
            return UIImage(data: imageData)
        }
        else {
            return UIImage(named: "PodverseIcon")
        }
    }
    
    private static func fetchPodcastImage(podcastFeedUrl: String) -> UIImage? {
        let moc = CoreDataHelper.createMOCForThread(threadType: .mainThread)
        
        let predicate = NSPredicate(format: "feedUrl == %@", podcastFeedUrl)
        if let podcastSet = CoreDataHelper.fetchEntities(className: "Podcast", predicate: predicate, moc:moc) as? [Podcast], let imageData = podcastSet.first?.imageData {
            return UIImage(data:imageData)
        }
        else {
            return nil
        }
    }
    
    private static func fetchPodcastImage(podcastImageUrl: URL, completion: @escaping (_ podcastImage: UIImage?) -> Void) {
        let session = URLSession(configuration: .default)
        _ = session.dataTask(with: podcastImageUrl) { (data, response, error) in
            DispatchQueue.main.async {
                var cellImage:UIImage?
                
                if let e = error {
                    print("Error downloading picture: \(e)")
                    cellImage = UIImage(named: "PodverseIcon")
                } else {
                    if let _ = response as? HTTPURLResponse, let imageData = data {
                        cellImage = UIImage(data: imageData)
                    } else {
                        print("Couldn't get image response")
                        cellImage = UIImage(named: "PodverseIcon")
                    }
                }
                
                completion(cellImage)
            }
            }.resume()
    }
    
}
