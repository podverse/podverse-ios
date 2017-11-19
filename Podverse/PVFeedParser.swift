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
    
    var feedUrl: String?
    let moc = CoreDataHelper.createMOCForThread(threadType: .privateThread)
    
    var onlyGetMostRecentEpisode: Bool
    var subscribeToPodcast: Bool
    var downloadMostRecentEpisode = false
    var onlyParseChannel = false
    var latestEpisodePubDate:Date?
    var delegate:PVFeedParserDelegate?
    let parsingPodcastsList = ParsingPodcastsList.shared
    
    init(shouldOnlyGetMostRecentEpisode:Bool, shouldSubscribe:Bool, shouldOnlyParseChannel:Bool) {
        self.onlyGetMostRecentEpisode = shouldOnlyGetMostRecentEpisode
        self.subscribeToPodcast = shouldSubscribe
        self.onlyParseChannel = shouldOnlyParseChannel
    }
    
    func parsePodcastFeed(feedUrlString:String) {

        parsingPodcastsList.addPodcast(feedUrl: feedUrlString)
        
        self.feedUrl = feedUrlString
        let feedParser = ExtendedFeedParser(feedUrl: feedUrlString)
        feedParser.delegate = self
        
        if onlyParseChannel {
            channelInfoFeedParsingQueue.async {
                // This apparently does nothing. The 3rd party FeedParser automatically sets the parsingType to .Full...
                feedParser.parsingType = .channelOnly
                feedParser.parse()
                print("feedParser did start")
            }
        } else {
            feedParsingQueue.async {
                feedParser.parsingType = .full
                feedParser.parse()
                print("feedParser did start")
            }
        }
    }
}

extension PVFeedParser:FeedParserDelegate {
    
    func feedParser(_ parser: FeedParser, didParseChannel channel: FeedChannel) {
        let podcast:Podcast!
        
        if let feedUrlString = channel.channelURL {
            podcast = CoreDataHelper.retrieveExistingOrCreateNewPodcast(feedUrlString: feedUrlString, moc: moc)
            podcast.feedUrl = feedUrlString
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
        
        if let imageUrlString = channel.channelLogoURL, let imageURL = URL(string:imageUrlString) {
            podcast.imageUrl = imageURL.absoluteString
            do {
                podcast.imageData = try Data(contentsOf: imageURL)
            }
            catch {
                print("No Image Data at give URL")
            }
        }
        
        if let iTunesImageUrlString = channel.channeliTunesLogoURL, let itunesImageURL = URL(string:iTunesImageUrlString) {
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
        
        if let lastBuildDate = channel.channelLastBuildDate {
            podcast.lastBuildDate = lastBuildDate
        }
        
        if let lastPubDate = channel.channelLastPubDate {
            podcast.lastPubDate = lastPubDate
        }
        
        if let categories = channel.channelCategory {
            podcast.categories = categories
        }
        
        moc.saveData {
            //If only parsing for the latest episode, do not reload the PodcastTableVC after the channel is parsed.
            //This will prevent PodcastTableVC UI from reloading and sticking unnecessarily.
            if self.onlyGetMostRecentEpisode != true {
                self.delegate?.feedParserChannelParsed()
            }
        }
    }
    
    func feedParser(_ parser: FeedParser, didParseItem item: FeedItem) {

        // This hack is put in to prevent parsing items unnecessarily. Ideally this would be handled by setting feedParser.parsingType to .ChannelOnly, but the 3rd party FeedParser does not let us override the .parsingType I think...
        if self.onlyParseChannel {
            return
        }

        guard let feedUrl = self.feedUrl, let podcast = Podcast.podcastForFeedUrl(feedUrlString: feedUrl, managedObjectContext: moc) else {
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

        newEpisode.mediaUrl = item.feedEnclosures[0].url
        newEpisode.mediaType = item.feedEnclosures[0].type
        newEpisode.mediaBytes = NSNumber(value: item.feedEnclosures[0].length)
        if let guid = item.feedIdentifier { newEpisode.guid = guid }

        // If only parsing for the latest episode, stop parsing after parsing the first episode.
        if onlyGetMostRecentEpisode == true {
            latestEpisodePubDate = newEpisode.pubDate
            CoreDataHelper.deleteItemFromCoreData(deleteObjectID: newEpisodeID, moc: moc)
            moc.saveData(nil)
            parser.abortParsing()
            return
        }

        // If episode already exists in the database, do not insert new episode
        if let mediaUrl = newEpisode.mediaUrl, let _ = Episode.episodeForMediaUrl(mediaUrlString: mediaUrl) {
            CoreDataHelper.deleteItemFromCoreData(deleteObjectID: newEpisodeID, moc: moc)
            moc.saveData(nil)
        } else {
            podcast.addEpisodeObject(value: newEpisode)
            moc.saveData({ [weak self] in
                guard let strongSelf = self else {
                    return
                }

                if strongSelf.downloadMostRecentEpisode == true && podcast.shouldAutoDownload() {
                    PVDownloader.shared.startDownloadingEpisode(episode: newEpisode)
                    strongSelf.downloadMostRecentEpisode = false
                }
            })
        }

    }
    
    func feedParser(_ parser: FeedParser, successfullyParsedURL url: String) {
        
        parsingPodcastsList.podcastFinishedParsing()
        
        guard let feedUrl = self.feedUrl, let podcast = Podcast.podcastForFeedUrl(feedUrlString: feedUrl, managedObjectContext: moc) else {
            return
        }
        
        let podcastPredicate = NSPredicate(format: "podcast == %@", podcast)
        
        // If subscribing to a podcast, then get the latest episode and begin downloading
        if subscribeToPodcast == true {
            if let latestEpisode = CoreDataHelper.fetchEntityWithMostRecentPubDate(className:"Episode", predicate: podcastPredicate, moc:moc) as? Episode {
                if latestEpisode.fileName == nil {
                    PVDownloader.shared.startDownloadingEpisode(episode: latestEpisode)
                }
            }
            podcast.addToAutoDownloadList()
        }
        
        if let mostRecentEpisode = CoreDataHelper.fetchEntityWithMostRecentPubDate(className:"Episode", predicate: podcastPredicate, moc:moc) as? Episode {
            podcast.lastPubDate = mostRecentEpisode.pubDate
            moc.saveData(nil)
        }
        
        self.delegate?.feedParsingComplete(feedUrl: podcast.feedUrl)
        
        print("Feed parser has finished!")
    }
    
    func feedParserParsingAborted(_ parser: FeedParser) {
        
        guard let feedUrl = self.feedUrl, let podcast = Podcast.podcastForFeedUrl(feedUrlString: feedUrl, managedObjectContext: moc) else {
            parsingPodcastsList.podcastFinishedParsing()
            self.delegate?.feedParsingComplete(feedUrl:nil)
            return
        }
        
        // If the parser is only returning the latest episode, then if the podcast's latest episode returned is not the same as the latest episode saved locally, parse the entire feed again, then download and save the latest episode
        if let latestEpisodePubDateInRSSFeed = latestEpisodePubDate, self.onlyGetMostRecentEpisode == true {
            let podcastPredicate = NSPredicate(format: "podcast == %@", podcast)
            
            let mostRecentEpisode = CoreDataHelper.fetchEntityWithMostRecentPubDate(className: "Episode", predicate: podcastPredicate, moc: moc) as? Episode
            
            if mostRecentEpisode == nil {
                parseAndDownloadMostRecentEpisode(feedUrl: feedUrl)
            } else if let mostRecentEpisode = mostRecentEpisode, let mostRecentPubDate = mostRecentEpisode.pubDate, latestEpisodePubDateInRSSFeed != mostRecentPubDate {
                parseAndDownloadMostRecentEpisode(feedUrl: feedUrl)
            }
            else {
                parsingPodcastsList.podcastFinishedParsing()
                self.delegate?.feedParsingComplete(feedUrl: feedUrl)
            }
        } else {
            print("No newer episode available, don't download")
        }
    }
    
    func parseAndDownloadMostRecentEpisode (feedUrl: String) {
        self.onlyGetMostRecentEpisode = false
        self.downloadMostRecentEpisode = true
        self.parsePodcastFeed(feedUrlString: feedUrl)
    }
}
