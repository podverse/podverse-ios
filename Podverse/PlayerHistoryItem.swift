//
//  PlayerHistoryItem.swift
//  Podverse
//
//  Created by Mitchell Downey on 5/21/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

import UIKit

class PlayerHistoryItem: NSObject, NSCoding {
    
    var mediaRefId: String?
    let podcastFeedUrl: String?
    let podcastTitle: String?
    let podcastImageUrl: String?
    let episodeDuration: Int64?
    let episodeImageUrl: String?
    let episodeMediaUrl: String?
    let episodePubDate: Date?
    let episodeSummary: String?
    let episodeTitle: String?
    var startTime: Int64?     // If startTime and endTime = 0, then item is a clip, else it is an episode
    var endTime: Int64?
    var clipTitle: String?
    var ownerName: String?
    var ownerId: String?
    var hasReachedEnd: Bool?
    var lastPlaybackPosition: Int64?
    var lastUpdated: Date?
    
    required init(mediaRefId:String? = nil, podcastFeedUrl:String? = nil, podcastTitle:String? = nil, podcastImageUrl:String? = nil, episodeDuration: Int64? = nil, episodeMediaUrl:String? = nil, episodeTitle:String? = nil, episodeImageUrl:String? = nil, episodeSummary:String? = nil, episodePubDate:Date? = nil, startTime:Int64? = nil, endTime:Int64? = nil, clipTitle:String? = nil, ownerName:String? = nil, ownerId:String? = nil, hasReachedEnd:Bool, lastPlaybackPosition:Int64? = 0, lastUpdated:Date? = nil) {
        self.mediaRefId = mediaRefId
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
        self.mediaRefId = decoder.decodeObject(forKey: "mediaRefId") as? String
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
        coder.encode(mediaRefId, forKey: "mediaRefId")
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
    
    func isClip() -> Bool {
        
        if let startTime = self.startTime {
            if startTime > 0 {
                return true
            }
        } else if let endTime = self.endTime {
            if endTime > 0 {
                return true
            }
        }
        
        return false
    }
    
    func convertClipToEpisode() -> PlayerHistoryItem {
        self.clipTitle = nil
        self.startTime = 0
        self.endTime = nil
        self.ownerName = nil
        self.ownerId = nil
        self.hasReachedEnd = false
        self.lastPlaybackPosition = nil
        self.lastUpdated = nil
        
        return self
    }
    
    func readableStartAndEndTime() -> String? {
        var time: String?
        
        if let startTime = self.startTime {
            if let endTime = self.endTime {
                if endTime > 0 {
                    time = startTime.toMediaPlayerString() + " to " + endTime.toMediaPlayerString()
                }
            } else if startTime == 0 {
                time = "--:--"
            } else {
                time = "Starts:" + startTime.toMediaPlayerString()
            }
        }
        
        return time
    }
    
}
