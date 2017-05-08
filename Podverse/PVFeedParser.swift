//
//  PVFeedParser.swift
//  Podverse
//
//  Created by Creon on 12/24/16.
//  Copyright © 2016 Podverse LLC. All rights reserved.
//

import Foundation
import CoreData

protocol PVFeedParserDelegate {
    func feedParsingComplete(feedUrl:String?)
    func feedParserStarted()
    func feedParserChannelParsed()
}

extension PVFeedParserDelegate {
    func feedParserStarted() { }
    func feedParserChannelParsed() { }
}

class PVFeedParser {
    let moc = CoreDataHelper.createMOCForThread(threadType: .privateThread)
    var feedURL: String!
    var currentPodcastID: NSManagedObjectID? = nil
    
    var onlyGetMostRecentEpisode: Bool
    var subscribeToPodcast: Bool
    var followPodcast: Bool
    var downloadMostRecentEpisode = false
    var onlyParseChannel = false
    var latestEpisodePubDate:Date?
    var delegate:PVFeedParserDelegate?
    let parsingPodcasts = ParsingPodcastsList.shared
    
    init(shouldOnlyGetMostRecentEpisode:Bool, shouldSubscribe:Bool, shouldFollowPodcast:Bool, shouldOnlyParseChannel:Bool) {
        self.onlyGetMostRecentEpisode = shouldOnlyGetMostRecentEpisode
        self.subscribeToPodcast = shouldSubscribe
        self.followPodcast = shouldFollowPodcast
        self.onlyParseChannel = shouldOnlyParseChannel
    }
    
    func parsePodcastFeed(feedURLString:String) {
        if onlyParseChannel {
            channelInfoFeedParsingQueue.async {
                self.feedURL = feedURLString
                let feedParser = ExtendedFeedParser(feedURL: feedURLString)
                feedParser.delegate = self
                // This apparently does nothing. The 3rd party FeedParser automatically sets the parsingType to .Full...
                feedParser.parsingType = .channelOnly
                feedParser.parse()
                print("feedParser did start")
            }
        } else {
            feedParsingQueue.async {
                self.feedURL = feedURLString
                let feedParser = ExtendedFeedParser(feedURL: feedURLString)
                feedParser.delegate = self
                feedParser.parsingType = .full
                feedParser.parse()
                print("feedParser did start")
//                DispatchQueue.main.async {
//                    self.delegate?.feedParserStarted()
//                }
            }
        }
    }
}

extension PVFeedParser:FeedParserDelegate {
    
    func feedParser(_ parser: FeedParser, didParseChannel channel: FeedChannel) {
        let podcast:Podcast!
        
        if let feedURLString = channel.channelURL {
            podcast = CoreDataHelper.retrieveExistingOrCreateNewPodcast(feedUrlString: feedURLString, moc: moc)
        }
        else {
            return
        }
        
        if let title = channel.channelTitle {
            podcast.title = title
        }
        
        if let summary = channel.channelDescription {
            podcast.summary = summary
        }
        
        if let iTunesAuthor = channel.channeliTunesAuthor {
            podcast.author = iTunesAuthor
        }
        
        if let podcastLink = channel.channelLink {
            podcast.link = podcastLink
        }
        
        podcast.feedURL = feedURL
        
        if let imageUrlString = channel.channelLogoURL, let imageURL = URL(string:imageUrlString) {
            podcast.imageURL = imageURL.absoluteString
            do {
                podcast.imageData = try Data(contentsOf: imageURL)
            }
            catch {
                print("No Image Data at give URL")
            }
        }
        
        if let iTunesImageUrlString = channel.channeliTunesLogoURL, let itunesImageURL = URL(string:iTunesImageUrlString) {
            podcast.itunesImageURL = itunesImageURL.absoluteString
            do {
                podcast.itunesImage = try Data(contentsOf: itunesImageURL)
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
        
        if let lastBuildDate = channel.channelLastBuildDate {
            podcast.lastBuildDate = lastBuildDate
        }
        
        if let lastPubDate = channel.channelLastPubDate {
            podcast.lastPubDate = lastPubDate
        }
        
        if let categories = channel.channelCategory {
            podcast.categories = categories
        }
        
        if self.subscribeToPodcast {
            podcast.isSubscribed = true
            podcast.isFollowed = true
        }
        
        if self.followPodcast {
            podcast.isSubscribed = false
            podcast.isFollowed = true
        }
        
        currentPodcastID = podcast.objectID
        
        moc.saveData { 
            DispatchQueue.main.async {
                //If only parsing for the latest episode, do not reload the PodcastTableVC after the channel is parsed.
                //This will prevent PodcastTableVC UI from reloading and sticking unnecessarily.
                if self.onlyGetMostRecentEpisode != true {
                    self.delegate?.feedParserChannelParsed()
                }
            }
        }
    }
    
    func feedParser(_ parser: FeedParser, didParseItem item: FeedItem) {
        // This hack is put in to prevent parsing items unnecessarily. Ideally this would be handled by setting feedParser.parsingType to .ChannelOnly, but the 3rd party FeedParser does not let us override the .parsingType I think...
        if self.onlyParseChannel {
            return
        }
        
        guard let podcastId = currentPodcastID, let podcast = CoreDataHelper.fetchEntityWithID(objectId: podcastId, moc: moc) as? Podcast else {
            // If podcast is nil, then the RSS feed was invalid for the parser, and we should return out of successfullyParsedURL
            return
        }
        
        //Do not parse episode if it does not contain feedEnclosures.
        if item.feedEnclosures.count <= 0 {
            return
        }
        
        let newEpisodeID = CoreDataHelper.insertManagedObject(className: "Episode", moc: moc)
        let newEpisode = CoreDataHelper.fetchEntityWithID(objectId: newEpisodeID, moc: moc) as! Episode
        
        // Retrieve parsed values from item and add values to their respective episode properties
        if let title = item.feedTitle { newEpisode.title = title }
        if let summary = item.feedContent { newEpisode.summary = summary }
        if let date = item.feedPubDate { newEpisode.pubDate = date }
        if let link = item.feedLink { newEpisode.link = link }
        if let duration = item.duration { newEpisode.duration = duration }
        
        newEpisode.mediaURL = item.feedEnclosures[0].url
        newEpisode.mediaType = item.feedEnclosures[0].type
        newEpisode.mediaBytes = NSNumber(value: item.feedEnclosures[0].length)
        if let guid = item.feedIdentifier { newEpisode.guid = guid }
        
        newEpisode.taskIdentifier = nil
        
        // If only parsing for the latest episode, stop parsing after parsing the first episode.
        if onlyGetMostRecentEpisode == true {
            latestEpisodePubDate = newEpisode.pubDate
            CoreDataHelper.deleteItemFromCoreData(deleteObjectID: newEpisodeID)
            moc.saveData(nil)
            parser.abortParsing()
            return
        }
        
        // If episode already exists in the database, do not insert new episode
        if podcast.episodes.contains(where: { $0.mediaURL == newEpisode.mediaURL }) {
            CoreDataHelper.deleteItemFromCoreData(deleteObjectID: newEpisodeID)
            moc.saveData(nil)
        }
        else {
            podcast.addEpisodeObject(value: newEpisode)
            moc.saveData({ [weak self] in
                guard let strongSelf = self else {
                    return
                }
                
                if strongSelf.downloadMostRecentEpisode == true {
                    PVDownloader.shared.startDownloadingEpisode(episode: newEpisode)
                    strongSelf.downloadMostRecentEpisode = false
                }
            })
        }
    }
    
    func feedParser(_ parser: FeedParser, successfullyParsedURL url: String) {
        parsingPodcasts.itemsParsing += 1
        parsingPodcasts.clearParsingPodcastsIfFinished()
        
        guard let podcastId = currentPodcastID, let podcast = CoreDataHelper.fetchEntityWithID(objectId: podcastId, moc: moc) as? Podcast else {
            return
        }
        
        // If subscribing to a podcast, then get the latest episode and begin downloading
        if subscribeToPodcast == true {
            let podcastPredicate = NSPredicate(format: "podcast == %@", podcast)
            if let latestEpisode = CoreDataHelper.fetchEntityWithMostRecentPubDate(className:"Episode", predicate: podcastPredicate, moc:moc) as? Episode {
                if latestEpisode.downloadComplete != true {
                    PVDownloader.shared.startDownloadingEpisode(episode: latestEpisode)
                }
            }
        }
        
        DispatchQueue.main.async {
            self.delegate?.feedParsingComplete(feedUrl: podcast.feedURL)
        }
        print("Feed parser has finished!")
    }
    
    func feedParserParsingAborted(_ parser: FeedParser) {
        parsingPodcasts.itemsParsing += 1
        parsingPodcasts.clearParsingPodcastsIfFinished()
        
        guard let podcastId = currentPodcastID, let podcast = CoreDataHelper.fetchEntityWithID(objectId: podcastId, moc: moc) as? Podcast else {
            // If podcast is nil, then the RSS feed was invalid for the parser, and we should return out of successfullyParsedURL
            
            DispatchQueue.main.async {
                self.delegate?.feedParsingComplete(feedUrl:nil)
            }
            
            return
        }
        
        // If the parser is only returning the latest episode, then if the podcast's latest episode returned is not the same as the latest episode saved locally, 
        // parse the entire feed again, then download and save the latest episode
        if let latestEpisodePubDateInRSSFeed = latestEpisodePubDate, self.onlyGetMostRecentEpisode == true {
            let podcastPredicate = NSPredicate(format: "podcast == %@", podcast)
            
            if let mostRecentEpisode = CoreDataHelper.fetchEntityWithMostRecentPubDate(className: "Episode", predicate: podcastPredicate, moc: moc) as? Episode,
               let mostRecentPubDate = mostRecentEpisode.pubDate, latestEpisodePubDateInRSSFeed != mostRecentPubDate {
                self.onlyGetMostRecentEpisode = false
                self.downloadMostRecentEpisode = true
                self.parsePodcastFeed(feedURLString: podcast.feedURL)
            }
            else {
                DispatchQueue.main.async {
                    self.delegate?.feedParsingComplete(feedUrl: podcast.feedURL)
                }
            }
        } else {
            print("No newer episode available, don't download")
        }
    }
}
