//
//  PVDownloader.swift
//  Podverse
//
//  Created by Creon on 12/24/16.
//  Copyright © 2016 Podverse LLC. All rights reserved.
//

import Foundation
import UIKit
import CoreData

extension Notification.Name {
    static let downloadStarted = Notification.Name("downloadStarted")
    static let downloadPaused = Notification.Name("downloadPaused")
    static let downloadProgressed = Notification.Name("downloadProgressed")
    static let downloadResumed = Notification.Name("downloadResumed")
    static let downloadFinished = Notification.Name("downloadFinished")
}

class PVDownloader:NSObject {
    static let shared = PVDownloader()
    var appDelegate = UIApplication.shared.delegate as! AppDelegate
    var docDirectoryURL: URL?
    var downloadSession: URLSession!
    let reachability = PVReachability.shared
    static let episodeKey = "episodeKey"
    
    override init() {
        super.init()
        let sessionConfiguration = URLSessionConfiguration.background(withIdentifier: "podverse.download.episodes")
        
        let URLs = FileManager().urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask)
        docDirectoryURL = URLs.first
        
        // Initialize the session configuration, then create the session
        sessionConfiguration.httpMaximumConnectionsPerHost = 3
        sessionConfiguration.allowsCellularAccess = false
        
        downloadSession = URLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)
    }

    func pauseDownloadingEpisode(downloadingEpisode: DownloadingEpisode) {
        downloadSession.getTasksWithCompletionHandler( { dataTasks, uploadTasks, downloadTasks in
            for episodeDownloadTask in downloadTasks {
                if episodeDownloadTask.taskIdentifier == downloadingEpisode.taskIdentifier {
                    episodeDownloadTask.cancel(byProducingResumeData: { (resumeData) in
                        if resumeData != nil {
                            downloadingEpisode.taskResumeData = resumeData
                            DispatchQueue.main.async {
                                NotificationCenter.default.post(name: .downloadPaused, object: nil, userInfo: [Episode.episodeKey:downloadingEpisode])
                            }
                        }
                    })
                }
            }
        })
    }
    
    func resumeDownloadingEpisode(downloadingEpisode: DownloadingEpisode) {
        if let downloadTaskResumeData = downloadingEpisode.taskResumeData {
            let downloadTask = downloadSession.downloadTask(withResumeData: downloadTaskResumeData)
            downloadingEpisode.taskIdentifier = downloadTask.taskIdentifier
            downloadingEpisode.taskResumeData = nil
            
            let taskID = beginBackgroundTask()
            downloadTask.resume()
            endBackgroundTask(taskID)
            
            DispatchQueue.main.async {
               NotificationCenter.default.post(name: .downloadResumed, object: nil, userInfo: [Episode.episodeKey:downloadingEpisode])
            }
        }
    }
    
    func startDownloadingEpisode(episode: Episode) {
        if let downloadSourceStringURL = episode.mediaUrl, let downloadSourceURL = URL(string: downloadSourceStringURL) {
            let downloadTask = downloadSession.downloadTask(with: downloadSourceURL)
            
            let downloadingEpisode = DownloadingEpisode(episode:episode)
            
            downloadingEpisode.taskIdentifier = downloadTask.taskIdentifier
            
            if !DownloadingEpisodeList.shared.downloadingEpisodes.contains(where: { downloadingEpisode in downloadingEpisode.mediaUrl == episode.mediaUrl }) {
                DownloadingEpisodeList.shared.downloadingEpisodes.insert(downloadingEpisode, at: 0)
                incrementBadge()
            } else {
                print("that's already downloading / downloaded")
                return
            }
            
            let taskID = beginBackgroundTask()
            downloadTask.resume()
            endBackgroundTask(taskID)
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .downloadStarted, object: nil, userInfo: [Episode.episodeKey:downloadingEpisode])
            }
        }
    }
    
    func decrementBadge() {
        if let tabBarCntrl = self.appDelegate.window?.rootViewController as? UITabBarController {
            if let badgeValue = tabBarCntrl.tabBar.items?[TabItems.More.index].badgeValue, let badgeInt = Int(badgeValue) {
                tabBarCntrl.tabBar.items?[TabItems.More.index].badgeValue = "\(badgeInt - 1)"
                if tabBarCntrl.tabBar.items?[TabItems.More.index].badgeValue == "0" {
                    tabBarCntrl.tabBar.items?[TabItems.More.index].badgeValue = nil
                }
            }
        }
    }
    
    fileprivate func incrementBadge() {
        DispatchQueue.main.async {
            if let tabBarCntrl = self.appDelegate.window?.rootViewController as? UITabBarController {
                if let badgeValue = tabBarCntrl.tabBar.items?[TabItems.More.index].badgeValue, let badgeInt = Int(badgeValue) {
                    tabBarCntrl.tabBar.items?[TabItems.More.index].badgeValue = "\(badgeInt + 1)"
                }
                else {
                    tabBarCntrl.tabBar.items?[TabItems.More.index].badgeValue = "1"
                }
            }
        }
    }
    
    fileprivate func beginBackgroundTask() -> UIBackgroundTaskIdentifier {
        return UIApplication.shared.beginBackgroundTask(expirationHandler: {})
    }
    
    fileprivate func endBackgroundTask(_ taskID: UIBackgroundTaskIdentifier) {
        UIApplication.shared.endBackgroundTask(taskID)
    }
}

extension PVDownloader:URLSessionDelegate, URLSessionDownloadDelegate {
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if (totalBytesExpectedToWrite == NSURLSessionTransferSizeUnknown) {
            print("Unknown transfer size")
        }
        else {
            if let episodeDownloadIndex = DownloadingEpisodeList.shared.downloadingEpisodes.index(where: {$0.taskIdentifier == downloadTask.taskIdentifier}) {
                let downloadingEpisode = DownloadingEpisodeList.shared.downloadingEpisodes[episodeDownloadIndex]
                downloadingEpisode.totalBytesWritten = Float(totalBytesWritten)
                downloadingEpisode.totalBytesExpectedToWrite = Float(totalBytesExpectedToWrite)
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .downloadProgressed, object: nil, userInfo: [Episode.episodeKey:downloadingEpisode])
                }
            }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let fileManager = FileManager()
        print("did finish downloading")
        let moc = CoreDataHelper.createMOCForThread(threadType: .privateThread)
        
        // Get the corresponding episode object by its taskIdentifier value
        if let downloadingEpisode = DownloadingEpisodeList.shared.downloadingEpisodes.first(where: {$0.taskIdentifier == downloadTask.taskIdentifier}) {
            
            guard let mediaUrl =  downloadingEpisode.mediaUrl else {
                return
            }
            
            let predicate = NSPredicate(format: "mediaUrl == %@", mediaUrl)
            guard let episode = CoreDataHelper.fetchEntities(className:"Episode", predicate: predicate, moc: moc).first as? Episode else {
                return
            }
            
            var mp3OrOggFileExtension = ".mp3"
            
            if episode.mediaUrl?.hasSuffix(".ogg") == true {
                mp3OrOggFileExtension = ".ogg"
            }
            
            // If file is already downloaded for this episode, remove the old file before saving the new one
            if let fileName = episode.fileName {
                let destinationURL = self.docDirectoryURL?.appendingPathComponent(fileName)
                
                if let path = destinationURL?.path {
                    do {
                        try fileManager.removeItem(atPath: path)
                    } catch {
                        print(error.localizedDescription)
                    }
                }
            }
            
            // TODO: why must we add .mp3 or .ogg to the end of the file name in order for the media player to play the file? What would happen if a downloaded file is not actually an .mp3 or .ogg?
            let destinationFilename = NSUUID().uuidString + mp3OrOggFileExtension
            let destinationURL = self.docDirectoryURL?.appendingPathComponent(destinationFilename)
            
            do {
                if let destination = destinationURL {
                    try fileManager.copyItem(at: location, to: destination)
                    
//                    episode.taskResumeData = nil
                    
                    // Add the file destination to the episode object for playback and retrieval
                    episode.fileName = destinationFilename
                    
                    for downloadingEpisode in DownloadingEpisodeList.shared.downloadingEpisodes where episode.mediaUrl == downloadingEpisode.mediaUrl {
                        downloadingEpisode.downloadComplete = true
                        downloadingEpisode.taskIdentifier = nil
                    }
                    
                    var episodeTitle = ""
                    if let title = episode.title {
                        episodeTitle = title
                    }
                    
                    let podcastTitle = episode.podcast.title
                    // Save the downloadedMediaFileDestination with the object
                    moc.saveData {                        
                        DispatchQueue.main.async { _ in
                            NotificationCenter.default.post(name: .downloadFinished, object: nil, userInfo: [Episode.episodeKey:downloadingEpisode])

                            let notification = UILocalNotification()
                            notification.applicationIconBadgeNumber = UIApplication.shared.applicationIconBadgeNumber + 1
                            notification.alertBody = podcastTitle + " - " + episodeTitle
                            notification.alertAction = "open"
                            notification.soundName = UILocalNotificationDefaultSoundName
                            UIApplication.shared.presentLocalNotificationNow(notification)
                            
                            PVDownloader.shared.decrementBadge()
                        }
                    }
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        //TODO: Handle erroring out the downloading proccess
        //        if let episodeDownloadIndex = DLEpisodesList.shared.downloadingEpisodes.indexOf({$0.taskIdentifier == task.taskIdentifier}) {
        //            let episode = DLEpisodesList.shared.downloadingEpisodes[episodeDownloadIndex]
        //
        //            if let resumeData = error?.userInfo[NSURLSessionDownloadTaskResumeData] as? NSData {
        //                episode.taskResumeData = resumeData
        //            }
        //        }
    }
}
