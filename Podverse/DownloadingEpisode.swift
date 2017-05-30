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
    var imageThumbData:Data?
    var taskResumeData:Data?
    var totalBytesWritten:Float?
    var totalBytesExpectedToWrite:Float?
    var podcastRSSfeedUrl:String?
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
        taskIdentifier = episode.taskIdentifier?.intValue
        downloadComplete = episode.downloadComplete
        mediaUrl = episode.mediaUrl
        imageThumbData = episode.podcast.imageThumbData
        podcastRSSfeedUrl = episode.podcast.feedUrl
        wasPausedByUser = false
        pausedWithoutResumeData = false
        managedEpisodeObjectID = episode.objectID
    }
}

func == (lhs: DownloadingEpisode, rhs: DownloadingEpisode) -> Bool {
    return lhs.mediaUrl == rhs.mediaUrl
}
