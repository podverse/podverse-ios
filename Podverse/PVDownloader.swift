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

class PVDownloader:NSObject {
    static let shared = PVDownloader()
    var appDelegate = UIApplication.shared.delegate as! AppDelegate
    var docDirectoryURL: URL?
    var downloadSession: URLSession!
    let reachability = PVReachability.shared
    
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
    
    func startDownloadingEpisode (episode: Episode) {
        episode.downloadComplete = false
        if let downloadSourceStringURL = episode.mediaURL, let downloadSourceURL = URL(string: downloadSourceStringURL) {
            let downloadTask = downloadSession.downloadTask(with: downloadSourceURL)
            
            episode.managedObjectContext?.perform {
                episode.taskIdentifier = NSNumber(value:downloadTask.taskIdentifier)
                episode.managedObjectContext?.saveData(nil)
            }
            
            let downloadingEpisode = DownloadingEpisode(episode:episode)
            if !DownloadingEpisodeList.shared.downloadingEpisodes.contains(downloadingEpisode) {
                DownloadingEpisodeList.shared.downloadingEpisodes.append(downloadingEpisode)
                incrementBadge()
            }
            // If downloadingEpisode already exists then update it with the new taskIdentifier
            else {
                if let matchingDLEpisode = DownloadingEpisodeList.shared.downloadingEpisodes.first(where: { $0 == downloadingEpisode })  {
                    matchingDLEpisode.taskIdentifier = episode.taskIdentifier?.intValue
                }
            }
            
            let taskID = self.beginBackgroundTask()
            downloadTask.resume()
            self.endBackgroundTask(taskID)
            
            self.postPauseOrResumeNotification(taskIdentifier: downloadTask.taskIdentifier, pauseOrResume: "Downloading")
        }
    }
    
    func pauseOrResumeDownloadingEpisode(episode: DownloadingEpisode) {
        // If the episode has already downloaded, then do nothing
        if (episode.downloadComplete == true) {
            episode.taskIdentifier = nil
        }
        // Else if the episode download is paused, then resume the download
        else if let downloadTaskResumeData = episode.taskResumeData {
            let downloadTask = downloadSession.downloadTask(withResumeData: downloadTaskResumeData)
            episode.taskIdentifier = downloadTask.taskIdentifier
            episode.taskResumeData = nil
            episode.wasPausedByUser = false
            downloadTask.resume()
            self.postPauseOrResumeNotification(taskIdentifier: downloadTask.taskIdentifier, pauseOrResume: "Downloading")
        }
        else if episode.pausedWithoutResumeData == true {
            episode.pausedWithoutResumeData = false
            let moc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            moc.parent = CoreDataHelper.shared.managedObjectContext
            
            if let episodeObjectID = episode.managedEpisodeObjectID {
                if let nsManagedEpisode = CoreDataHelper.fetchEntityWithID(objectId: episodeObjectID, moc: moc) as? Episode {
                    startDownloadingEpisode(episode: nsManagedEpisode)
                }
            }
        }
        // Else if the episode has a taskIdentifier, then pause the download if it has already begun
        else if let taskIdentifier = episode.taskIdentifier {
            downloadSession.getTasksWithCompletionHandler { dataTasks, uploadTasks, downloadTasks in
                for episodeDownloadTask in downloadTasks {
                    if episodeDownloadTask.taskIdentifier == taskIdentifier {
                        episodeDownloadTask.cancel(byProducingResumeData: { (resumeData) in
                            if (resumeData != nil) {
                                episode.taskResumeData = resumeData
                                if self.reachability.hasWiFiConnection() == true {
                                    episode.wasPausedByUser = true
                                    self.postPauseOrResumeNotification(taskIdentifier: taskIdentifier, pauseOrResume: "Paused")
                                }
                                else {
                                    self.postPauseOrResumeNotification(taskIdentifier: taskIdentifier, pauseOrResume: "Connect to WiFi")
                                }
                                episode.taskIdentifier = nil
                            } else {
                                episode.pausedWithoutResumeData = true
                                if self.reachability.hasWiFiConnection() == true {
                                    episode.wasPausedByUser = true
                                    self.postPauseOrResumeNotification(taskIdentifier: taskIdentifier, pauseOrResume: "Paused")
                                }
                                else {
                                    self.postPauseOrResumeNotification(taskIdentifier: taskIdentifier, pauseOrResume: "Connect to WiFi")
                                }
                            }
                        })
                    }
                }
            }
        }
    }
    
    func postPauseOrResumeNotification(taskIdentifier: Int, pauseOrResume: String) {
        // Get the corresponding episode object by its taskIdentifier value
        if let episodeDownloadIndex = DownloadingEpisodeList.shared.downloadingEpisodes.index(where: {$0.taskIdentifier == taskIdentifier}) {
            if episodeDownloadIndex < DownloadingEpisodeList.shared.downloadingEpisodes.count {
                let episode = DownloadingEpisodeList.shared.downloadingEpisodes[episodeDownloadIndex]
                
                let downloadHasPausedOrResumedUserInfo:[String:Any] = ["mediaUrl":episode.mediaURL ?? "", "pauseOrResume": pauseOrResume]
                
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: kDownloadHasPausedOrResumed), object: self, userInfo: downloadHasPausedOrResumedUserInfo)
                }
            }
        }
    }
    
    fileprivate func decrementBadge() {
        if let tabBarCntrl = self.appDelegate.window?.rootViewController as? UITabBarController {
            if let badgeValue = tabBarCntrl.tabBar.items?[TabItems.Downloads.index].badgeValue, let badgeInt = Int(badgeValue) {
                tabBarCntrl.tabBar.items?[TabItems.Downloads.index].badgeValue = "\(badgeInt - 1)"
                if tabBarCntrl.tabBar.items?[TabItems.Downloads.index].badgeValue == "0" {
                    tabBarCntrl.tabBar.items?[TabItems.Downloads.index].badgeValue = nil
                }
            }
        }
    }
    
    fileprivate func incrementBadge() {
        DispatchQueue.main.async {
            if let tabBarCntrl = self.appDelegate.window?.rootViewController as? UITabBarController {
                if let badgeValue = tabBarCntrl.tabBar.items?[TabItems.Downloads.index].badgeValue, let badgeInt = Int(badgeValue) {
                    tabBarCntrl.tabBar.items?[TabItems.Downloads.index].badgeValue = "\(badgeInt + 1)"
                }
                else {
                    tabBarCntrl.tabBar.items?[TabItems.Downloads.index].badgeValue = "1"
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
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        if (totalBytesExpectedToSend == NSURLSessionTransferSizeUnknown) {
            print("Unknown transfer size")
        }
        else {
            // Get the corresponding episode object by its taskIdentifier value
            if let episodeDownloadIndex = DownloadingEpisodeList.shared.downloadingEpisodes.index(where: {$0.taskIdentifier == task.taskIdentifier}) {
                let episode = DownloadingEpisodeList.shared.downloadingEpisodes[episodeDownloadIndex]
                episode.totalBytesWritten = Float(totalBytesSent)
                episode.totalBytesExpectedToWrite = Float(totalBytesExpectedToSend)
                
                let downloadHasProgressedUserInfo:[String:Any] = ["mediaUrl":episode.mediaURL ?? "",
                                                                  "totalBytes": Double(totalBytesExpectedToSend),
                                                                  "currentBytes": Double(totalBytesSent)]
                
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name:NSNotification.Name(rawValue: kDownloadHasProgressed), object: self, userInfo: downloadHasProgressedUserInfo)
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
            
            guard let mediaUrl =  downloadingEpisode.mediaURL else {
                return
            }
            
            let predicate = NSPredicate(format: "mediaURL == %@", mediaUrl)
            guard let episode = CoreDataHelper.fetchEntities(className:"Episode", predicate: predicate, moc: moc).first as? Episode else {
                return
            }
            
            var mp3OrOggFileExtension = ".mp3"
            
            if episode.mediaURL?.hasSuffix(".ogg") == true {
                mp3OrOggFileExtension = ".ogg"
            }
            
            // If file is already downloaded for this episode, remove the old file before saving the new one
            if let fileName = episode.fileName {
                let destinationURL = self.docDirectoryURL?.appendingPathComponent(fileName)
                
                if let path = destinationURL?.path {
                    do {
                        try fileManager.removeItem(atPath: path)
                    } catch {
                        print(error)
                    }
                }
            }
            
            // TODO: why must we add .mp3 or .ogg to the end of the file name in order for the media player to play the file? What would happen if a downloaded file is not actually an .mp3 or .ogg?
            let destinationFilename = NSUUID().uuidString + mp3OrOggFileExtension
            let destinationURL = self.docDirectoryURL?.appendingPathComponent(destinationFilename)
            
            do {
                if let destination = destinationURL {
                    try fileManager.copyItem(at: location, to: destination)
                    
                    episode.downloadComplete = true
                    
                    episode.taskResumeData = nil
                    
                    // Add the file destination to the episode object for playback and retrieval
                    episode.fileName = destinationFilename
                    
                    // Reset the episode.downloadTask to nil before saving, or the app will crash
                    episode.taskIdentifier = nil
                    
                    for downloadingEpisode in DownloadingEpisodeList.shared.downloadingEpisodes where episode.mediaURL == downloadingEpisode.mediaURL {
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
                        let downloadHasFinishedUserInfo = ["episode":episode]
                        
                        DispatchQueue.main.async { [weak self] in
                            guard let strongSelf = self else {
                                return
                            }
                            
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: kDownloadHasFinished), object: strongSelf, userInfo: downloadHasFinishedUserInfo)
                            
                            // TODO: When a download finishes and Podverse is in the background, two localnotifications show in the UI. Why are we receiving two instead of one, when only one notification is getting scheduled below?
                            let notification = UILocalNotification()
                            notification.applicationIconBadgeNumber = UIApplication.shared.applicationIconBadgeNumber + 1
                            notification.alertBody = podcastTitle + " - " + episodeTitle // text that will be displayed in the notification
                            notification.alertAction = "open"
                            notification.soundName = UILocalNotificationDefaultSoundName // play default sound
                            UIApplication.shared.presentLocalNotificationNow(notification)
                            
                            strongSelf.decrementBadge()
                        }
                    }
                }
            } catch {
                print(error)
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
