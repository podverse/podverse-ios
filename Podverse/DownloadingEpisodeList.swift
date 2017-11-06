//
//  DownloadingEpisodeList.swift
//  Podverse
//
//  Created by Creon on 12/24/16.
//  Copyright © 2016 Podverse LLC. All rights reserved.
//

import Foundation


final class DownloadingEpisodeList {
    static var shared = DownloadingEpisodeList()
    
    var downloadingEpisodes = [DownloadingEpisode]()
    
    static func removeDownloadingEpisodeWithMediaURL(mediaUrl:String?) {
        var downloadingEpisodes = DownloadingEpisodeList.shared.downloadingEpisodes
        
        if let mediaUrl = mediaUrl, let index = downloadingEpisodes.index(where: { $0.mediaUrl == mediaUrl }), index < downloadingEpisodes.count {
            downloadingEpisodes[index].removeFromDownloadHistory()
            DownloadingEpisodeList.shared.downloadingEpisodes.remove(at: index)
        }
    }
}
