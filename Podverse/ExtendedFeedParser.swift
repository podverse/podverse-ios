//
//  ExtendedFeedParser.swift
//  Podverse
//
//  Created by Creon on 12/24/16.
//  Copyright © 2016 Podverse LLC. All rights reserved.
//


import Foundation

class ExtendedFeedParser:FeedParser {
    
    override func parseEndOfRSS2Element(_ elementName: String, qualifiedName qName: String!) {
        // TODO: This maxFeedsToParse should probably be limited in some way. Such as, only retrieve the last 100 episodes, but return the next 100 episodes if the user scrolls to the bottom of the EpisodesTableView.
        // Also, for some reason the maxFeedsToParse will only return half the number of episodes maxFeedsToParse we set. So 100 would actually result in 50 episodes.
        self.maxFeedsToParse = 5000

        if self.currentPath == "/rss/channel/image/url"{
            self.currentFeedChannel?.channelLogoURL = self.currentElementContent
        }
        else if self.currentPath == "/rss/channel/itunes:image" {
            self.currentFeedChannel.channeliTunesLogoURL = self.currentElementAttributes["href"] as? String
        }
        else if self.currentPath == "/rss/channel/itunes:author" {
            self.currentFeedChannel?.channeliTunesAuthor = self.currentElementContent
        }
        else if self.currentPath == "/rss/channel/item/itunes:duration" {
            // if the : is present, then the duration is in hh:mm:ss
            if self.currentElementContent.contains(":") {
                self.currentFeedItem?.duration = PVTimeHelper.convertServerDurationToNumber(durationString: self.currentElementContent);
            }
            // else the duration is an integer in seconds
            else {
                if let durationInteger = Int(self.currentElementContent) {
                    self.currentFeedItem?.duration = NSNumber(value: durationInteger)
                }
            }
        }
        else if self.currentPath == "/rss/channel/lastBuildDate" {
            self.currentFeedChannel.channelLastBuildDate = Date(fromString: self.currentElementContent, format: .rfc822)
        }
        else if self.currentPath == "/rss/channel/pubDate" {
            self.currentFeedChannel.channelLastPubDate = Date(fromString: self.currentElementContent, format: .rfc822)
        }
        // category
        else if self.currentPath == "/rss/channel/category" || self.currentPath == "/rss/channel/itunes:category" {
            if currentElementAttributes != nil {
                if let channelCategory = self.currentFeedChannel?.channelCategory, let categoryText = currentElementAttributes["text"], let categoryTextString = categoryText as? String {
                    self.currentFeedChannel?.channelCategory = channelCategory + ", " + categoryTextString
                } else {
                    self.currentFeedChannel?.channelCategory = currentElementAttributes["text"] as? String
                }
            }
        }
        
        super.parseEndOfRSS2Element(elementName, qualifiedName: qName)
    }
}
