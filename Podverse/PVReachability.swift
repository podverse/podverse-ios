//
//  PVReachability.swift
//  Podverse
//
//  Created by Creon on 12/25/16.
//  Copyright © 2016 Podverse LLC. All rights reserved.
//

import Foundation
import ReachabilitySwift

class PVReachability {
    static let shared = PVReachability()
    let reachability = Reachability()!
    
    init() {
        reachability.whenReachable = { reachability in
            if !reachability.isReachableViaWiFi
            {
                self.pauseDownloadingEpisodesUntilWiFi()
            } else {
                self.resumeDownloadingEpisodes()
            }
            
            if UserDefaults.standard.object(forKey: "ONE_TIME_LOGIN") != nil && UserDefaults.standard.bool(forKey: "DefaultPlaylistsCreated") == false {
//                TODO:
//                let playlistManager = PlaylistManager.sharedInstance
//                playlistManager.getMyPlaylistsFromServer({
//                    playlistManager.createDefaultPlaylists()
//                })
            }
        }
        
        reachability.whenUnreachable = { reachability in
            if !reachability.isReachableViaWiFi {
                self.pauseDownloadingEpisodesUntilWiFi()
            }
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(name:NSNotification.Name(rawValue: kInternetIsUnreachable), object: self, userInfo: nil)
            }
            
        }

        do {
            try reachability.startNotifier()
        } catch {
            print("Unable to start reachability notifier")
        }
    }
    
    func hasInternetConnection() -> Bool {
        return reachability.isReachable
    }
    
    func hasWiFiConnection() -> Bool {
        return reachability.isReachableViaWiFi
    }
    
    // TODO: move to PVDownloader without causing splash screen to hang indefinitely
    func pauseDownloadingEpisodesUntilWiFi() {
        let downloader = PVDownloader.shared
        downloader.downloadSession.getTasksWithCompletionHandler { dataTasks, uploadTasks, downloadTasks in
            for downloadingEpisode in DownloadingEpisodeList.shared.downloadingEpisodes {
                if let taskIdentifier = downloadingEpisode.taskIdentifier {
                    for episodeDownloadTask in downloadTasks {
                        if episodeDownloadTask.taskIdentifier == taskIdentifier {
                            downloader.pauseOrResumeDownloadingEpisode(episode: downloadingEpisode)
                        }
                    }
                }
            }
        }
    }
    
    // TODO: move to PVDownloader without causing splash screen to hang indefinitely
    func resumeDownloadingEpisodes() {
        let downloader = PVDownloader.shared
        downloader.downloadSession.getTasksWithCompletionHandler { dataTasks, uploadTasks, downloadTasks in
            for downloadingEpisode in DownloadingEpisodeList.shared.downloadingEpisodes {
                if (downloadingEpisode.taskResumeData != nil || downloadingEpisode.pausedWithoutResumeData == true) && downloadingEpisode.wasPausedByUser == false {
                    downloader.pauseOrResumeDownloadingEpisode(episode: downloadingEpisode)
                }
            }
        }
    }
    
    func createInternetConnectionNeededAlertWithDescription(_ message: String) -> UIAlertController {
        let connectionNeededAlert = UIAlertController(title: "Internet Connection Needed", message: message, preferredStyle: UIAlertControllerStyle.alert)
        connectionNeededAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        connectionNeededAlert.addAction(UIAlertAction(title: "Settings", style: .default) { (_) -> Void in
            let settingsURL = URL(string: UIApplicationOpenSettingsURLString)
            if let url = settingsURL {
                UIApplication.shared.openURL(url)
            }
        })
        return connectionNeededAlert
    }
}
