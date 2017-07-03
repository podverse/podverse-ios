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
    let episodeMediaUrl: String?
    let episodeTitle: String?
    let episodeImageUrl: String?
    let episodeSummary: String?
    let episodeDuration: NSNumber?
    let episodePubDate: Date?
    let startTime: NSNumber?     // If startTime and endTime = 0, then item is a clip, else it is an episode
    let endTime: NSNumber?
    let clipTitle: String?
    let clipDescription: String?
    let ownerName: String?
    let ownerId: String?
    let didFinishPlaying: Bool
    let lastPlaybackPosition: NSNumber?
    let lastUpdated: Date?
    
    required init(podcastFeedUrl:String? = nil, podcastTitle:String? = nil, podcastImageUrl:String? = nil, episodeMediaUrl:String? = nil, episodeTitle:String? = nil, episodeImageUrl:String? = nil, episodeSummary:String? = nil, episodeDuration:NSNumber? = nil, episodePubDate:Date? = nil, startTime:NSNumber? = nil, endTime:NSNumber? = nil, clipTitle:String? = nil, clipDescription:String? = nil, ownerName:String? = nil, ownerId:String? = nil, didFinishPlaying:Bool, lastPlaybackPosition:NSNumber? = 0, lastUpdated:Date? = nil) {
        self.podcastFeedUrl = podcastFeedUrl
        self.podcastTitle = podcastTitle
        self.podcastImageUrl = podcastImageUrl
        self.episodeMediaUrl = episodeMediaUrl
        self.episodeTitle = episodeTitle
        self.episodeImageUrl = episodeImageUrl
        self.episodeSummary = episodeSummary
        self.episodeDuration = episodeDuration
        self.episodePubDate = episodePubDate
        self.startTime = startTime
        self.endTime = endTime
        self.clipTitle = clipTitle
        self.clipDescription = clipDescription
        self.ownerName = ownerName
        self.ownerId = ownerId
        self.didFinishPlaying = didFinishPlaying
        self.lastPlaybackPosition = lastPlaybackPosition
        self.lastUpdated = lastUpdated
    }
    
    required init(coder decoder: NSCoder) {
        self.podcastFeedUrl = decoder.decodeObject(forKey: "podcastFeedUrl") as? String ?? ""
        self.podcastTitle = decoder.decodeObject(forKey: "podcastTitle") as? String ?? ""
        self.podcastImageUrl = decoder.decodeObject(forKey: "podcastImageUrl") as? String ?? ""
        self.episodeMediaUrl = decoder.decodeObject(forKey: "episodeMediaUrl") as? String ?? ""
        self.episodeTitle = decoder.decodeObject(forKey: "episodeTitle") as? String ?? ""
        self.episodeImageUrl = decoder.decodeObject(forKey: "episodeImageUrl") as? String ?? ""
        self.episodeSummary = decoder.decodeObject(forKey: "episodeSummary") as? String ?? ""
        self.episodeDuration = decoder.decodeObject(forKey: "episodeDuration") as? NSNumber ?? 0
        self.episodePubDate = decoder.decodeObject(forKey: "episodePubDate") as? Date ?? Date()
        self.startTime = decoder.decodeObject(forKey: "startTime") as? NSNumber ?? 0
        self.endTime = decoder.decodeObject(forKey: "endTime") as? NSNumber ?? 0
        self.clipTitle = decoder.decodeObject(forKey: "clipTitle") as? String ?? ""
        self.clipDescription = decoder.decodeObject(forKey: "clipDescription") as? String ?? ""
        self.ownerName = decoder.decodeObject(forKey: "ownerName") as? String ?? ""
        self.ownerId = decoder.decodeObject(forKey: "ownerId") as? String ?? ""
        self.didFinishPlaying = decoder.decodeObject(forKey: "didFinishPlaying") as? Bool ?? false
        self.lastPlaybackPosition = decoder.decodeObject(forKey: "lastPlaybackPosition") as? NSNumber ?? 0
        self.lastUpdated = decoder.decodeObject(forKey: "lastUpdated") as? Date ?? Date()
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(podcastFeedUrl, forKey:"podcastFeedUrl")
        coder.encode(podcastTitle, forKey:"podcastTitle")
        coder.encode(podcastImageUrl, forKey:"podcastImageUrl")
        coder.encode(episodeMediaUrl, forKey:"episodeMediaUrl")
        coder.encode(episodeTitle, forKey:"episodeTitle")
        coder.encode(episodeImageUrl, forKey:"episodeImageUrl")
        coder.encode(episodeSummary, forKey:"episodeSummary")
        coder.encode(episodeDuration, forKey:"episodeDuration")
        coder.encode(episodePubDate, forKey:"episodePubDate")
        coder.encode(startTime, forKey:"startTime")
        coder.encode(endTime, forKey:"endTime")
        coder.encode(clipTitle, forKey:"clipTitle")
        coder.encode(clipDescription, forKey:"clipDescription")
        coder.encode(ownerName, forKey:"ownerName")
        coder.encode(ownerId, forKey:"ownerId")
        coder.encode(didFinishPlaying, forKey:"didFinishPlaying")
        coder.encode(lastPlaybackPosition, forKey:"lastPlaybackPosition")
        coder.encode(lastUpdated, forKey:"lastUpdated")
    }
    
}
