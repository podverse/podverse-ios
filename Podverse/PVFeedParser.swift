//
//  PVFeedParser.swift
//  Podverse
//
//  Created by Creon on 12/24/16.
//  Copyright © 2016 Podverse LLC. All rights reserved.
//

import Foundation
import CoreData
import FeedKit

extension Notification.Name {
    static let feedParsingComplete = Notification.Name("feedParsingComplete")
    static let feedParsingStarted = Notification.Name("feedParsingStarted")
}

class PVFeedParser {
    var feedUrl:String?
    var onlyGetMostRecentEpisode: Bool
    var subscribeToPodcast: Bool
    var downloadMostRecentEpisode = false
    var latestEpisodePubDate:Date?
    let parsingPodcasts = ParsingPodcasts.shared
    var podcastId:String?
    
    let privateMoc = CoreDataHelper.createMOCForThread(threadType: .privateThread)
    
    init(shouldOnlyGetMostRecentEpisode:Bool, shouldSubscribe:Bool, podcastId:String?) {
        self.onlyGetMostRecentEpisode = shouldOnlyGetMostRecentEpisode
        self.subscribeToPodcast = shouldSubscribe
        self.podcastId = podcastId
    }
    
    func parsePodcastFeed(feedUrlString:String) {

        guard feedUrlString.count > 0, let url = URL(string: feedUrlString) else {
            self.parsingPodcasts.podcastFinishedParsing()
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .feedParsingComplete, object: nil, userInfo: ["feedUrl": feedUrlString])
            }
            return
        }

        // If the podcast is already in the parsing list AND should not be reparsed to download the latest episode, then do not add it again.
        if (self.parsingPodcasts.hasMatchingUrl(feedUrl: feedUrlString) || self.parsingPodcasts.hasMatchingId(podcastId: podcastId)) && !self.downloadMostRecentEpisode {
            self.parsingPodcasts.podcastFinishedParsing()
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .feedParsingComplete, object: nil, userInfo: ["feedUrl": feedUrlString])
            }
            return
        }

        if !self.downloadMostRecentEpisode {
            self.parsingPodcasts.addPodcast(podcastId: self.podcastId, feedUrl: feedUrlString)
        }
        
        self.feedUrl = feedUrlString
        
        let parser = FeedParser(URL: url)
        
        parser?.parseAsync(queue: DispatchQueue.global(qos: .background)) { (result) in
            
            switch result {
            case let .atom(feed):
                self.parseResultAtom(feed: feed)
            case let .rss(feed):
                self.parseResultRSS(feed: feed)
            case let .json(feed):
                self.parseResultJSON(feed: feed)
            case let .failure(error):
                print(error)
            }
            
            // If subscribing to a podcast, then get the latest episode and begin downloading
            if self.subscribeToPodcast == true {
                if let podcast = Podcast.podcastForFeedUrl(feedUrlString: feedUrlString, managedObjectContext: self.privateMoc) {
                    let podcastPredicate = NSPredicate(format: "podcast == %@", podcast)
                    if let latestEpisode = CoreDataHelper.fetchEntityWithMostRecentPubDate(className:"Episode", predicate: podcastPredicate, moc: self.privateMoc) as? Episode {
                        if latestEpisode.fileName == nil {
                            PVDownloader.shared.startDownloadingEpisode(episode: latestEpisode)
                            podcast.addToAutoDownloadList()
                        }
                    }
                }
            }
            
            // If the parser is only returning the latest episode, then if the podcast's latest episode returned is not the same as the latest episode saved locally, parse the entire feed again, then download and save the latest episode
            if let latestEpisodePubDate = self.latestEpisodePubDate, self.onlyGetMostRecentEpisode == true, let feedUrl = self.feedUrl {
                if let podcast = Podcast.podcastForFeedUrl(feedUrlString: feedUrlString, managedObjectContext: self.privateMoc) {
                    let podcastPredicate = NSPredicate(format: "podcast == %@", podcast)
                    let mostRecentEpisode = CoreDataHelper.fetchEntityWithMostRecentPubDate(className: "Episode", predicate: podcastPredicate, moc: self.privateMoc) as? Episode
                    
                    if mostRecentEpisode == nil {
                        self.parseAndDownloadMostRecentEpisode(feedUrl: feedUrl)
                    } else if let mostRecentEpisode = mostRecentEpisode, let mostRecentPubDate = mostRecentEpisode.pubDate, latestEpisodePubDate != mostRecentPubDate {
                        self.parseAndDownloadMostRecentEpisode(feedUrl: feedUrl)
                    } else {
                        self.parsingPodcasts.podcastFinishedParsing()
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: .feedParsingComplete, object: nil, userInfo: ["feedUrl": feedUrl])
                        }
                    }
                }
            } else {
                self.parsingPodcasts.podcastFinishedParsing()
                DispatchQueue.main.async {
                    if let feedUrl = self.feedUrl {
                        NotificationCenter.default.post(name: .feedParsingComplete, object: nil, userInfo: ["feedUrl": feedUrl])
                    }
                }
            }
        }
        
    }
    
    func parseAndDownloadMostRecentEpisode (feedUrl: String) {
        self.onlyGetMostRecentEpisode = false
        self.downloadMostRecentEpisode = true
        self.parsePodcastFeed(feedUrlString: feedUrl)
    }
    
    func parseResultAtom(feed:AtomFeed) {
        guard let feedUrl = self.feedUrl else { return }
        let podcast = CoreDataHelper.retrieveExistingOrCreateNewPodcast(feedUrlString: feedUrl, moc: self.privateMoc)
        
        if let podcastId = self.podcastId {
            podcast.id = podcastId
        }
        
        podcast.feedUrl = feedUrl
        
        if let title = feed.title {
            podcast.title = title
        }
        
        if let summary = feed.subtitle {
            podcast.summary = summary.value
        }
        
        if let iTunesAuthor = feed.authors?.description {
            podcast.author = iTunesAuthor
        }
        
        if let link = feed.links?.first?.attributes?.href {
            podcast.link = link
        }
        
        if let imageUrlString = feed.logo, let imageUrl = URL(string:imageUrlString) {
            podcast.imageUrl = imageUrl.absoluteString
            do {
                podcast.imageData = try Data(contentsOf: imageUrl)
            }
            catch {
                print("No image data at given URL.")
            }
        }
        
        if let downloadedImageData = podcast.imageData {
            podcast.imageThumbData = downloadedImageData.resizeImageData()
        }
        else if let downloadedImageData = podcast.itunesImage {
            podcast.imageThumbData = downloadedImageData.resizeImageData()
        }
        
        if let lastBuildDate = feed.updated {
            podcast.lastBuildDate = lastBuildDate
        }
        
        if let lastPubDate = feed.updated {
            podcast.lastPubDate = lastPubDate
        }
        
        if let categories = feed.categories {
            podcast.categories = categories.description
        }
        
        if let items = feed.entries {
            for item in items {
                guard let url = item.content?.attributes?.src else { continue }
                
                let episode = CoreDataHelper.retrieveExistingOrCreateNewEpisode(mediaUrlString: url, moc: self.privateMoc)
                
                if let title = item.title {
                    episode.title = title
                }
                
                if let summary = item.summary {
                    episode.summary = summary.value
                }
                
                if let date = item.published {
                    episode.pubDate = date
                    
                    if (item == items.first) {
                        self.latestEpisodePubDate = date
                        podcast.lastPubDate = date
                    }
                }
                
                if let link = item.links?.first {
                    episode.link = link.attributes?.href
                }
                
//                if let duration = item {
//                    episode.duration = duration as NSNumber
//                }
                
                episode.mediaUrl = url
                
                if let type = item.content?.attributes?.type {
                    episode.mediaType = type
                }

//                if let bytes = item.enclosure?.attributes?.length {
//                    episode.mediaBytes = bytes as NSNumber
//                }
                
                if let guid = item.id {
                    episode.guid = guid
                }
                
                podcast.addEpisodeObject(value: episode)
                
                if self.downloadMostRecentEpisode == true && podcast.shouldAutoDownload() {
                    PVDownloader.shared.startDownloadingEpisode(episode: episode)
                    self.downloadMostRecentEpisode = false
                }
                
                if self.onlyGetMostRecentEpisode {
                    break
                }
            }
        }
        
        self.privateMoc.saveData(nil)
    }
    
    func parseResultRSS(feed:RSSFeed) {
        guard let feedUrl = self.feedUrl else { return }
        let podcast = CoreDataHelper.retrieveExistingOrCreateNewPodcast(feedUrlString: feedUrl, moc: self.privateMoc)
        
        if let podcastId = self.podcastId {
            podcast.id = podcastId
        }
        
        podcast.feedUrl = feedUrl

        if let title = feed.title {
            podcast.title = title
        }

        if let summary = feed.description {
            podcast.summary = summary
        }
        
        if let iTunesAuthor = feed.iTunes?.iTunesAuthor {
            podcast.author = iTunesAuthor
        }

        if let link = feed.link {
            podcast.link = link
        }

        if let imageUrlString = feed.image?.url, let imageUrl = URL(string:imageUrlString) {
            podcast.imageUrl = imageUrl.absoluteString
            do {
                podcast.imageData = try Data(contentsOf: imageUrl)
            }
            catch {
                print("No image data at given URL.")
            }
        }
        
        if let iTunesImageUrlString = feed.iTunes?.iTunesImage?.attributes?.href, let itunesImageURL = URL(string:iTunesImageUrlString) {
            podcast.itunesImageUrl = itunesImageURL.absoluteString
            do {
                podcast.itunesImage = try Data(contentsOf: itunesImageURL)
                if podcast.imageData == nil {
                    podcast.imageData = try Data(contentsOf: itunesImageURL)
                    podcast.imageUrl = podcast.itunesImageUrl
                }
            }
            catch {
                print("No Image Data at give URL")
            }
        }

        if let downloadedImageData = podcast.imageData {
            podcast.imageThumbData = downloadedImageData.resizeImageData()
        }
        else if let downloadedImageData = podcast.itunesImage {
            podcast.imageThumbData = downloadedImageData.resizeImageData()
        }

        if let lastBuildDate = feed.lastBuildDate {
            podcast.lastBuildDate = lastBuildDate
        }

        if let lastPubDate = feed.pubDate {
            podcast.lastPubDate = lastPubDate
        }

        if let categories = feed.categories {
            podcast.categories = categories.description
        }
        
        if let items = feed.items {
            for item in items {
                guard let url = item.enclosure?.attributes?.url else { continue }
                
                let episode = CoreDataHelper.retrieveExistingOrCreateNewEpisode(mediaUrlString: url, moc: self.privateMoc)
                
                if let title = item.title {
                    episode.title = title
                }
                
                if let summary = item.description {
                    episode.summary = summary
                }
                
                if let date = item.pubDate {
                    episode.pubDate = date
                    
                    if (item == items.first) {
                        self.latestEpisodePubDate = date
                        podcast.lastPubDate = date
                    }
                }
                
                if let link = item.link {
                    episode.link = link
                }

                if let duration = item.iTunes?.iTunesDuration {
                    episode.duration = duration as NSNumber
                }

                episode.mediaUrl = url
                
                if let type = item.enclosure?.attributes?.type {
                    episode.mediaType = type
                }
                
                if let bytes = item.enclosure?.attributes?.length {
                    episode.mediaBytes = bytes as NSNumber
                }
                
                if let guid = item.guid {
                    episode.guid = guid.value
                }

                podcast.addEpisodeObject(value: episode)

                if self.downloadMostRecentEpisode == true && podcast.shouldAutoDownload() {
                    PVDownloader.shared.startDownloadingEpisode(episode: episode)
                    self.downloadMostRecentEpisode = false
                }
                
                if self.onlyGetMostRecentEpisode {
                    break
                }
            }
        }
        
        self.privateMoc.saveData(nil)
        
    }
    
    func parseResultJSON(feed:JSONFeed) {
        
        guard let feedUrl = self.feedUrl else { return }
        let podcast = CoreDataHelper.retrieveExistingOrCreateNewPodcast(feedUrlString: feedUrl, moc: self.privateMoc)
        
        if let podcastId = self.podcastId {
            podcast.id = podcastId
        }
        
        podcast.feedUrl = feedUrl
        
        if let title = feed.title {
            podcast.title = title
        }
        
        if let summary = feed.description {
            podcast.summary = summary
        }
        
        if let author = feed.author {
            podcast.author = author.name
        }
        
        if let link = feed.homePageURL {
            podcast.link = link
        }
        
        if let imageUrlString = feed.icon, let imageUrl = URL(string:imageUrlString) {
            podcast.imageUrl = imageUrl.absoluteString
            do {
                podcast.imageData = try Data(contentsOf: imageUrl)
            }
            catch {
                print("No image data at given URL.")
            }
        }
        
        if let downloadedImageData = podcast.imageData {
            podcast.imageThumbData = downloadedImageData.resizeImageData()
        }
        else if let downloadedImageData = podcast.itunesImage {
            podcast.imageThumbData = downloadedImageData.resizeImageData()
        }
        
//        if let categories = feed.categories {
//            podcast.categories = categories.description
//        }
        
        if let items = feed.items {
            for item in items {
                guard let url = item.attachments?.first?.url else { continue }
                
                let episode = CoreDataHelper.retrieveExistingOrCreateNewEpisode(mediaUrlString: url, moc: self.privateMoc)
                
                if let title = item.title {
                    episode.title = title
                }
                
                if let summary = item.summary {
                    episode.summary = summary
                }
                
                if let date = item.datePublished {
                    episode.pubDate = date
                    
                    if (item == items.first) {
                        self.latestEpisodePubDate = date
                        podcast.lastPubDate = date
                        podcast.lastBuildDate = date
                    }
                }
                
                if let link = item.url {
                    episode.link = link
                }
                
                if let duration = item.attachments?.first?.durationInSeconds {
                    episode.duration = duration as NSNumber
                }
                
                episode.mediaUrl = url
                
                if let type = item.attachments?.first?.mimeType {
                    episode.mediaType = type
                }
                
                if let bytes = item.attachments?.first?.sizeInBytes {
                    episode.mediaBytes = bytes as NSNumber
                }
                
                if let guid = item.id {
                    episode.guid = guid
                }
                
                podcast.addEpisodeObject(value: episode)
                
                if self.downloadMostRecentEpisode == true && podcast.shouldAutoDownload() {
                    PVDownloader.shared.startDownloadingEpisode(episode: episode)
                    self.downloadMostRecentEpisode = false
                }
                
                if self.onlyGetMostRecentEpisode {
                    break
                }
            }
        }
        
        self.privateMoc.saveData(nil)
        
    }
    
}
