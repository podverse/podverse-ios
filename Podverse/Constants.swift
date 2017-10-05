//
//  Constants.swift
//  Podverse
//
//  Created by Creon on 12/24/16.
//  Copyright © 2016 Podverse LLC. All rights reserved.
//

import Foundation

enum TabItems:Int {
    case Podcasts = 0, Clips, Find, Downloads, More
    
    var index:Int {
        switch self {
        case .Podcasts:
            return 0
        case .Clips:
            return 1
        case .Find:
            return 2
        case .Downloads:
            return 3
        case .More:
            return 4
        }
    }
}

enum SharePermission:String {
    case isPrivate = "isPrivate", isSharableWithLink = "isSharableWithLink", isPublic = "isPublic"
}

let DEV_URL = "http://localhost:8080/"
let PROD_URL = "https://podverse.fm/"
let BASE_URL = DEV_URL

let kNowPlayingTag = 100

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

let kAutoDownloadingFeedUrls = "autoDownloadingFeedUrls"

let kDownloadingMediaUrls = "downloadingMediaUrls"

let kClipsTableFilterType = "ClipsListFilterType"

let kClipsListFilterType = "ClipsListFilterType"

let kInternetIsUnreachable = "internetIsUnreachable"

let kWiFiIsUnreachable = "wiFiIsUnreachable"

let kNoDataViewTag = 999

let kBeginParsingPodcast = "beginParsingPodcast"

let kFinishedAllParsingPodcasts = "finishedAllParsingPodcasts"

let kFinishedParsingPodcast = "finishedParsingPodcast"

let rootPath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, .userDomainMask, true)[0]

let TO_PLAYER_SEGUE_ID = "To Now Playing"

let ErrorDomain = Bundle.main.bundleIdentifier!
let CoreDataFailureCode = -9999

enum ClipFilter: String {
    case allPodcasts = "All Podcasts"
    case episode = "Episode"
    case podcast = "Podcast"
    case subscribed = "Subscribed"
    
    var text:String {
        get {
            switch self {
            case .allPodcasts:
                return "All Podcasts"
            case .episode:
                return "Episode"
            case .podcast:
                return "Podcast"
            case .subscribed:
                return "Subscribed"
            }
        }
    }
}

enum EpisodeFilter: String {
    case downloads = "Downloads"
    case allEpisodes = "All Episodes"
    case clips = "Clips"
    
    var text:String {
        get {
            switch self {
            case .downloads:
                return "Downloads"
            case .allEpisodes:
                return "All Episodes"
            case .clips:
                return "Clips"
            }
        }
    }
}
