//
//  Constants.swift
//  Podverse
//
//  Created by Creon on 12/24/16.
//  Copyright © 2016 Podverse LLC. All rights reserved.
//

import Foundation

enum TabItems:Int {
    case Podcasts = 0, Clips, Playlists, Find, More
    
    var index:Int {
        switch self {
        case .Podcasts:
            return 0
        case .Clips:
            return 1
        case .Playlists:
            return 2
        case .Find:
            return 3
        case .More:
            return 4
        }
    }
}

enum SharePermission:String {
    case isPrivate = "isPrivate", isSharableWithLink = "isSharableWithLink", isPublic = "isPublic"
}


let kDownloadHasFinished  = "downloadHasFinished"

let kDownloadHasProgressed = "downloadHasProgressed"

let kDownloadHasPausedOrResumed = "downloadHasPausedOrResumed"

let kLastPlayingEpisodeURL = "lastPlayingEpisodeURL"

let kUnfollowPodcast = "unfollowPodcast"

let kUpdateDownloadsTable = "updateDownloadTable"

let kNowPlayingTimeHasChanged = "nowPlayingTimeHasChanged"

let kPlayerHasNoItem = "playerHasNoItem"

let feedParsingQueue = DispatchQueue(label: "FEED_PARSER_QUEUE")

let channelInfoFeedParsingQueue = DispatchQueue(label: "CHANNEL_INFO_FEED_PARSER_QUEUE")

let kRefreshAddToPlaylistTableDataNotification = "refreshPodcastTableDataNotification"

let kItemAddedToPlaylistNotification = "itemAddedToPlaylistNotificiation"

let kMyClipsPlaylist = "My Clips"

let kMyEpisodesPlaylist = "My Episodes"

let kUserId = "userId"

let kInternetIsUnreachable = "internetIsUnreachable"

let kWiFiIsUnreachable = "wiFiIsUnreachable"

let rootPath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, .userDomainMask, true)[0]

let TO_PLAYER_SEGUE_ID = "To Now Playing"

let ErrorDomain = Bundle.main.bundleIdentifier!
let CoreDataFailureCode = -9999
