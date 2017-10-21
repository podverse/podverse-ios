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

let kClipsTableFilterType = "ClipsTableFilterType"

let kClipsTableSortingType = "ClipsTableSortingType"

let kClipsListFilterType = "ClipsListFilterType"

let kClipsListSortingType = "ClipsListFilterType"

let kEpisodesTableFilterType = "EpisodesTableFilterType"

let kEpisodesTableSortingType = "EpisodesTableSortingType"

let kEpisodeTableFilterType = "EpisodeTableFilterType"

let kEpisodeTableSortingType = "EpisodeTableSortingType"

let kInternetIsUnreachable = "internetIsUnreachable"

let kWiFiIsUnreachable = "wiFiIsUnreachable"

let kDropdownCaret = " \u{2304}"

let kNoDataViewTag = 999

let kBeginParsingPodcast = "beginParsingPodcast"

let kFinishedAllParsingPodcasts = "finishedAllParsingPodcasts"

let kFinishedParsingPodcast = "finishedParsingPodcast"

let kNoShowNotesMessage = "No show notes available for this episode."

let kNoPodcastAboutMessage = "No information available for this podcast."

let rootPath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, .userDomainMask, true)[0]

let TO_PLAYER_SEGUE_ID = "To Now Playing"

let ErrorDomain = Bundle.main.bundleIdentifier!
let CoreDataFailureCode = -9999

let AudiosearchBaseUrl = URL(string: "https://www.audiosear.ch/api/")

enum SortByOptions: String {
    case top = "top"
    case recent = "recent"
    
    var text: String {
        get {
            switch self {
            case .top:
                return "Top"
            case .recent:
                return "Recent"
            }
        }
    }
}

enum SortingTimeRange: String {
    case hour = "hour"
    case day = "day"
    case week = "week"
    case month = "month"
    case year = "year"
    case allTime = "allTime"
    
    var text: String {
        get {
            switch self {
            case .hour:
                return "Hour"
            case .day:
                return "Day"
            case .week:
                return "Week"
            case .month:
                return "Month"
            case .year:
                return "Year"
            case .allTime:
                return "All Time"
            }
        }
    }
    
}

enum ClipSorting: String {
    case recent = "recent"
    case topHour = "top - past hour"
    case topDay = "top - past day"
    case topWeek = "top - past week"
    case topMonth = "top - past month"
    case topYear = "top - past year"
    case topAllTime = "top - all time"
    
    var text: String {
        get {
            switch self {
            case .recent:
                return "recent"
            case .topHour:
                return "top - past hour"
            case .topDay:
                return "top - past day"
            case .topWeek:
                return "top - past week"
            case .topMonth:
                return "top - past month"
            case .topYear:
                return "top - past year"
            case .topAllTime:
                return "top - all time"
            }
        }
    }
    
    var requestParam: String {
        get {
            switch self {
            case .recent:
                return "recent"
            case .topHour:
                return "pastHour"
            case .topDay:
                return "pastDay"
            case .topWeek:
                return "pastWeek"
            case .topMonth:
                return "pastMonth"
            case .topYear:
                return "pastYear"
            case .topAllTime:
                return "allTime"
            }
        }
    }
    
}

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

enum EpisodesFilter: String {
    case downloaded = "Downloaded"
    case allEpisodes = "All Episodes"
    case clips = "Clips"
    
    var text:String {
        get {
            switch self {
            case .downloaded:
                return "Downloaded"
            case .allEpisodes:
                return "All Episodes"
            case .clips:
                return "Clips"
            }
        }
    }
}

enum EpisodeFilter: String {
    case showNotes = "Show Notes"
    case clips = "Clips"
    
    var text:String {
        get {
            switch self {
            case .showNotes:
                return "Show Notes"
            case .clips:
                return "Clips"
            }
        }
    }
}

enum EpisodeActions: String {
    case stream = "Stream"
    case downloading = "Downloading"
    case download = "Download"
    case play = "Play"
    
    var text:String {
        get {
            switch self {
            case .stream:
                return "Stream"
            case .downloading:
                return "Downloading"
            case .download:
                return "Download"
            case .play:
                return "Play"
            }
        }
        
    }
}

enum AudiosearchPodcastFilter:String {
    case about = "About"
    case clips = "Clips"
    
    var text:String {
        get {
            switch self {
            case .about:
                return "About"
            case .clips:
                return "Clips"
            }
        }
    }
}

struct Strings {
    
    struct Errors {
        static let noClipsAvailable = "No clips available"
        static let noClipsInternet = "No internet connection"
        static let noDownloadedEpisodesAvailable = "No downloaded episodes available"
        static let noEpisodeClipsAvailable = "No clips available for this episode"
        static let noEpisodesAvailable = "No episodes available"
        static let noPlaylistsAvailable = "No playlists available"
        static let noPlaylistsInternet = "No internet connection"
        static let noPlaylistsNotLoggedIn = "Login to view your playlists"
        static let noPodcastClipsAvailable = "No clips available for this podcast"
    }
    
}
