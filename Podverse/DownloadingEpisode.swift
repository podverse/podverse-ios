//
//  DownloadingEpisode.swift
//  Podverse
//
//  Created by Creon on 12/24/16.
//  Copyright © 2016 Podverse LLC. All rights reserved.
//

import Foundation
import CoreData

final class DownloadingEpisode:Equatable {
    var downloadComplete:Bool?
    var mediaUrl: String?
    var pausedByUser:Bool?
    var pausedWithoutResumeData:Bool?
    var podcastFeedUrl:String?
    var podcastImageUrl: String?
    var podcastTitle:String?
    var taskIdentifier:Int?
    var taskResumeData:Data?
    var title:String?
    var totalBytesWritten:Float?
    var totalBytesExpectedToWrite:Float?
    
    var formattedTotalBytesDownloaded: String {
        get {
            if let currentBytes = totalBytesWritten, let totalBytes = totalBytesExpectedToWrite {
                // Format the total bytes into a human readable KB or MB number
                let dataFormatter = ByteCountFormatter()
                
                let formattedCurrentBytesDownloaded = dataFormatter.string(fromByteCount: Int64(currentBytes))
                let formattedTotalFileBytes = dataFormatter.string(fromByteCount: Int64(totalBytes))
                
                if progress == 1.0 {
                    return formattedTotalFileBytes
                } else {
                    return "\(formattedCurrentBytesDownloaded) / \(formattedTotalFileBytes)"
                }
            } else {
                return ""
            }
        }
    }
    
    var progress: Float {
        get {
            if let currentBytes = totalBytesWritten, let totalBytes = totalBytesExpectedToWrite {
                return currentBytes / totalBytes
            } else {
                return Float(0)
            }
        }
    }
    
    init(episode:Episode) {
        downloadComplete = false
        mediaUrl = episode.mediaUrl
        pausedByUser = false
        pausedWithoutResumeData = false
        podcastFeedUrl = episode.podcast.feedUrl
        podcastImageUrl = episode.podcast.imageUrl
        podcastTitle = episode.podcast.title
        taskIdentifier = nil
        taskResumeData = nil
        title = episode.title
        totalBytesWritten = nil
        totalBytesExpectedToWrite = nil
    }
}

func == (lhs: DownloadingEpisode, rhs: DownloadingEpisode) -> Bool {
    return lhs.mediaUrl == rhs.mediaUrl
}
