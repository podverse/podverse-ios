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
    var title:String?
    var taskIdentifier:Int?
    var downloadComplete:Bool?
    var mediaUrl: String?
    var taskResumeData:Data?
    var totalBytesWritten:Float?
    var totalBytesExpectedToWrite:Float?
    var podcastTitle:String?
    var podcastFeedUrl:String?
    var podcastImageUrl: String?
    var wasPausedByUser:Bool?
    var pausedWithoutResumeData:Bool?
    var managedEpisodeObjectID:NSManagedObjectID?
    
    var progress: Float {
        get {
            if let currentBytes = totalBytesWritten, let totalBytes = totalBytesExpectedToWrite {
                return currentBytes / totalBytes
            } else {
                return Float(0)
            }
        }
    }
    
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
    
    init(episode:Episode) {
        title = episode.title
        mediaUrl = episode.mediaUrl
        podcastTitle = episode.podcast.title
        podcastFeedUrl = episode.podcast.feedUrl
        podcastImageUrl = episode.podcast.imageUrl
        wasPausedByUser = false
        pausedWithoutResumeData = false
        managedEpisodeObjectID = episode.objectID
    }
}

func == (lhs: DownloadingEpisode, rhs: DownloadingEpisode) -> Bool {
    return lhs.mediaUrl == rhs.mediaUrl
}
