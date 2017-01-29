//
//  Constants.swift
//  Podverse
//
//  Created by Creon on 12/24/16.
//  Copyright © 2016 Podverse LLC. All rights reserved.
//

import Foundation

enum TabItems:Int {
    case Podcasts = 0, Playlists, Find, Downloads, Settings
    
    var index:Int {
        switch self {
        case .Podcasts:
            return 0
        case .Playlists:
            return 1
        case .Find:
            return 2
        case .Downloads:
            return 3
        case .Settings:
            return 4
        }
    }
}


enum SharePermission:String {
    case isPrivate = "isPrivate", isSharableWithLink = "isSharableWithLink", isPublic = "isPublic"
}

struct Constants {
    static let kDownloadHasFinished  = "downloadHasFinished"
    
    static let kDownloadHasProgressed = "downloadHasProgressed"
    
    static let kDownloadHasPausedOrResumed = "downloadHasPausedOrResumed"
    
    static let kLastPlayingEpisodeURL = "lastPlayingEpisodeURL"
    
    static let kUnfollowPodcast = "unfollowPodcast"
    
    static let kUpdateDownloadsTable = "updateDownloadTable"
    
    static let kNowPlayingTimeHasChanged = "nowPlayingTimeHasChanged"
    
    static let kPlayerHasNoItem = "playerHasNoItem"
    
    static let feedParsingQueue = DispatchQueue(label: "FEED_PARSER_QUEUE")
    
    static let channelInfoFeedParsingQueue = DispatchQueue(label: "CHANNEL_INFO_FEED_PARSER_QUEUE")
    
    static let kRefreshAddToPlaylistTableDataNotification = "refreshPodcastTableDataNotification"
    
    static let kItemAddedToPlaylistNotification = "itemAddedToPlaylistNotificiation"
    
    static let kMyClipsPlaylist = "My Clips"
    
    static let kMyEpisodesPlaylist = "My Episodes"
    
    static let kUserId = "userId"
    
    static let kInternetIsUnreachable = "internetIsUnreachable"
    
    static let kWiFiIsUnreachable = "wiFiIsUnreachable"
    
    static let rootPath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, .userDomainMask, true)[0]
    
    static let TO_PLAYER_SEGUE_ID = "To Now Playing"
    
    static let ErrorDomain = Bundle.main.bundleIdentifier!
    static let CoreDataFailureCode = -9999
}
