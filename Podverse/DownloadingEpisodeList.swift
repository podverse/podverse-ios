//
//  DownloadingEpisodeList.swift
//  Podverse
//
//  Created by Creon on 12/24/16.
//  Copyright © 2016 Podverse LLC. All rights reserved.
//

import UIKit

final class DownloadingEpisodeList {
    static var shared = DownloadingEpisodeList()
    
    var downloadingEpisodes = [DownloadingEpisode]()
    
    static func removeDownloadingEpisodeWithMediaURL(mediaUrl:String?) {
        var downloadingEpisodes = DownloadingEpisodeList.shared.downloadingEpisodes
        
        if let mediaUrl = mediaUrl, let index = downloadingEpisodes.index(where: { $0.mediaUrl == mediaUrl }), index < downloadingEpisodes.count {
            downloadingEpisodes[index].removeFromDownloadHistory()
            downloadingEpisodes.remove(at: index)
            PVDownloader.shared.decrementBadge()
            DownloadingEpisodeList.shared.downloadingEpisodes = downloadingEpisodes
        }
    }
    
    static func removeAllEpisodesForPodcast(feedUrl: String) {
        DownloadingEpisodeList.shared.downloadingEpisodes = DownloadingEpisodeList.shared.downloadingEpisodes.filter({$0.podcastFeedUrl != feedUrl})
    }
}
