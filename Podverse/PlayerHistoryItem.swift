//
//  PlayerHistoryItem.swift
//  Podverse
//
//  Created by Mitchell Downey on 5/21/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

import UIKit

class PlayerHistoryItem: NSObject, NSCoding {

    let podcastFeedUrl: String?
    let podcastTitle: String?
    let podcastImageUrl: String?
    let episodeDuration: Int64?
    let episodeImageUrl: String?
    let episodeMediaUrl: String?
    let episodePubDate: Date?
    let episodeSummary: String?
    let episodeTitle: String?
    let startTime: Int64?     // If startTime and endTime = 0, then item is a clip, else it is an episode
    let endTime: Int64?
    let clipTitle: String?
    let ownerName: String?
    let ownerId: String?
    var hasReachedEnd: Bool?
    let lastPlaybackPosition: Int64?
    let lastUpdated: Date?
    
    required init(podcastFeedUrl:String? = nil, podcastTitle:String? = nil, podcastImageUrl:String? = nil, episodeDuration: Int64? = nil, episodeMediaUrl:String? = nil, episodeTitle:String? = nil, episodeImageUrl:String? = nil, episodeSummary:String? = nil, episodePubDate:Date? = nil, startTime:Int64? = nil, endTime:Int64? = nil, clipTitle:String? = nil, ownerName:String? = nil, ownerId:String? = nil, hasReachedEnd:Bool, lastPlaybackPosition:Int64? = 0, lastUpdated:Date? = nil) {
        self.podcastFeedUrl = podcastFeedUrl
        self.podcastTitle = podcastTitle
        self.podcastImageUrl = podcastImageUrl
        self.episodeDuration = episodeDuration
        self.episodeMediaUrl = episodeMediaUrl
        self.episodeImageUrl = episodeImageUrl
        self.episodePubDate = episodePubDate
        self.episodeSummary = episodeSummary
        self.episodeTitle = episodeTitle
        self.startTime = startTime
        self.endTime = endTime
        self.clipTitle = clipTitle
        self.ownerName = ownerName
        self.ownerId = ownerId
        self.hasReachedEnd = hasReachedEnd
        self.lastPlaybackPosition = lastPlaybackPosition
        self.lastUpdated = lastUpdated
    }
    
    required init(coder decoder: NSCoder) {
        self.podcastFeedUrl = decoder.decodeObject(forKey: "podcastFeedUrl") as? String
        self.podcastTitle = decoder.decodeObject(forKey: "podcastTitle") as? String
        self.podcastImageUrl = decoder.decodeObject(forKey: "podcastImageUrl") as? String
        self.episodeDuration = decoder.decodeObject(forKey: "episodeDuration") as? Int64
        self.episodeImageUrl = decoder.decodeObject(forKey: "episodeImageUrl") as? String
        self.episodeMediaUrl = decoder.decodeObject(forKey: "episodeMediaUrl") as? String
        self.episodeSummary = decoder.decodeObject(forKey: "episodeSummary") as? String
        self.episodePubDate = decoder.decodeObject(forKey: "episodePubDate") as? Date
        self.episodeTitle = decoder.decodeObject(forKey: "episodeTitle") as? String
        self.startTime = decoder.decodeObject(forKey: "startTime") as? Int64 ?? 0
        self.endTime = decoder.decodeObject(forKey: "endTime") as? Int64
        self.clipTitle = decoder.decodeObject(forKey: "clipTitle") as? String
        self.ownerName = decoder.decodeObject(forKey: "ownerName") as? String
        self.ownerId = decoder.decodeObject(forKey: "ownerId") as? String
        self.hasReachedEnd = decoder.decodeObject(forKey: "hasReachedEnd") as? Bool
        self.lastPlaybackPosition = decoder.decodeObject(forKey: "lastPlaybackPosition") as? Int64
        self.lastUpdated = decoder.decodeObject(forKey: "lastUpdated") as? Date
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(podcastFeedUrl, forKey:"podcastFeedUrl")
        coder.encode(podcastTitle, forKey:"podcastTitle")
        coder.encode(podcastImageUrl, forKey:"podcastImageUrl")
        coder.encode(episodeDuration, forKey:"episodeDuration")
        coder.encode(episodeImageUrl, forKey:"episodeImageUrl")
        coder.encode(episodeMediaUrl, forKey:"episodeMediaUrl")
        coder.encode(episodePubDate, forKey:"episodePubDate")
        coder.encode(episodeSummary, forKey:"episodeSummary")
        coder.encode(episodeTitle, forKey:"episodeTitle")
        coder.encode(startTime, forKey:"startTime")
        coder.encode(endTime, forKey:"endTime")
        coder.encode(clipTitle, forKey:"clipTitle")
        coder.encode(ownerName, forKey:"ownerName")
        coder.encode(ownerId, forKey:"ownerId")
        coder.encode(hasReachedEnd, forKey:"hasReachedEnd")
        coder.encode(lastPlaybackPosition, forKey:"lastPlaybackPosition")
        coder.encode(lastUpdated, forKey:"lastUpdated")
    }
    
}
