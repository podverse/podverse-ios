//
//  AppDelegate.swift
//  Podverse
//
//  Created by Creon on 12/15/16.
//  Copyright © 2016 Podverse LLC. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer
import Lock
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?
    var backgroundTransferCompletionHandler: (() -> Void)?
    var timer: DispatchSource!
    let pvMediaPlayer = PVMediaPlayer.shared
    let playerHistoryManager = PlayerHistory.manager
    var networkCounter = 0 {
        didSet {
            if (networkCounter > 0) {
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = true
                }
            }
            else {
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
            }
        }
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // Enable the media player to continue playing in the background and on the lock screen
        // Enable the media player to use remote control events
        // Remote control events are overridden in the AppDelegate and set in remoteControlReceivedWithEvent
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
            UIApplication.shared.beginReceivingRemoteControlEvents()
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        
        let colorView = UIView()
        colorView.backgroundColor = UIColor.groupTableViewBackground
        UITableViewCell.appearance().selectedBackgroundView = colorView
        
        UIApplication.shared.statusBarStyle = .lightContent
        setupUI()
        setupRemoteFunctions()
        
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.sound, .alert, .badge]) { (granted, error) in
            if granted {
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()                    
                }
            }
        }
        
        // Load the last playerHistoryItem in the media player if the user didn't finish listening to it
        playerHistoryManager.loadData()
        if let previousItem = playerHistoryManager.historyItems.first {
            if previousItem.hasReachedEnd != true {
                pvMediaPlayer.loadPlayerHistoryItem(item: previousItem)
            }            
        }
        
        PVAuth.shared.syncUserInfoWithServer()
        
        PVDownloader.shared.resumeDownloadingAllEpisodes()
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        UIApplication.shared.applicationIconBadgeNumber = 0
        pvMediaPlayer.setPlayingInfo()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }

    func applicationWillTerminate(_ application: UIApplication) {
        if self.pvMediaPlayer.audioPlayer.rate > 0.1 {
            self.pvMediaPlayer.savePlaybackPosition()
        }
        
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        return Lock.resumeAuth(url, options: options)
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb, let url = userActivity.webpageURL, let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return false
        }
        
        let pathValues = components.path.components(separatedBy: "/")
        
        if pathValues.count > 2 {
            if pathValues[1] == "clips" {
                if let tabBar = self.window?.rootViewController as? UITabBarController {
                    DispatchQueue.main.async {
                        tabBar.goToNowPlaying(isDataAvailable:false)
                    }
                }
                
                let id = pathValues[2]
                MediaRef.retrieveMediaRefFromServer(id: id) { item in
                    if let item = item {
                        self.pvMediaPlayer.loadPlayerHistoryItem(item: item)
                    }
                }
            } else if pathValues[1] == "episodes" {
                if let tabBar = self.window?.rootViewController as? UITabBarController {
                    DispatchQueue.main.async {
                        tabBar.goToNowPlaying(isDataAvailable:false)
                    }
                }
                
                let id = pathValues[2]
                Episode.retrieveEpisodeFromServer(id: id) { item in
                    if let item = item {
                        self.pvMediaPlayer.loadPlayerHistoryItem(item: item)
                    }
                }
            } else if pathValues[1] == "playlists" {
                let id = pathValues[2]
                if let tabBar = self.window?.rootViewController as? UITabBarController {
                    DispatchQueue.main.async {
                        tabBar.goToPlaylistDetail(id: id)
                    }
                }
            }
        } else if let queryItems = components.queryItems, queryItems.count > 0 {
            var filterType:ClipFilter? = nil
            var sortingType:ClipSorting? = nil
            
            if let filter = url.getQueryParamValue("filter") {
                filterType = ClipFilter(rawValue: filter)
            }
            
            if let sort = url.getQueryParamValue("sort") {
                sortingType = ClipSorting(rawValue: sort)
            }
            
            if let tabBar = self.window?.rootViewController as? UITabBarController {
                DispatchQueue.main.async {
                    tabBar.goToClips(filterType, sortingType)
                }
            }
            
        } else if pathValues.count == 2 {
            if let tabBar = self.window?.rootViewController as? UITabBarController {
                DispatchQueue.main.async {
                    tabBar.goToClips()
                }
            }
        }
        
        return true
    }
    
    fileprivate func setupUI() {
        UINavigationBar.appearance().isTranslucent = false
        UINavigationBar.appearance().barTintColor = UIColor(red: 41.0/255.0, green: 104.0/255.0, blue: 177.0/255.0, alpha: 1.0)
        UINavigationBar.appearance().tintColor = UIColor.white
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white, NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 17.0)]
    }
    
    fileprivate func setupRemoteFunctions() {

        let rcc = MPRemoteCommandCenter.shared()

        let skipBackwardIntervalCommand = rcc.skipBackwardCommand
        skipBackwardIntervalCommand.addTarget(self, action: #selector(AppDelegate.skipBackwardEvent))

        let skipForwardIntervalCommand = rcc.skipForwardCommand
        skipForwardIntervalCommand.addTarget(self, action: #selector(AppDelegate.skipForwardEvent))

        let pauseCommand = rcc.pauseCommand
        pauseCommand.addTarget(self, action: #selector(AppDelegate.playOrPauseEvent))

        let playCommand = rcc.playCommand
        playCommand.addTarget(self, action: #selector(AppDelegate.playOrPauseEvent))

        let toggleCommand = rcc.togglePlayPauseCommand
        toggleCommand.addTarget(self, action: #selector(AppDelegate.playOrPauseEvent))

        if #available(iOS 9.1, *) {
            rcc.changePlaybackPositionCommand.isEnabled = true
            rcc.changePlaybackPositionCommand.addTarget(self, action: #selector(AppDelegate.updatePlaybackPosition))
        }

        rcc.bookmarkCommand.isEnabled = false
        rcc.changePlaybackRateCommand.isEnabled = false
        rcc.changeRepeatModeCommand.isEnabled = false
        rcc.changeShuffleModeCommand.isEnabled = false
        rcc.disableLanguageOptionCommand.isEnabled = false
        rcc.enableLanguageOptionCommand.isEnabled = false
        rcc.likeCommand.isEnabled = false
        rcc.nextTrackCommand.isEnabled = false
        rcc.previousTrackCommand.isEnabled = false
        rcc.ratingCommand.isEnabled = false
        rcc.seekBackwardCommand.isEnabled = false
        rcc.seekForwardCommand.isEnabled = false
        rcc.skipBackwardCommand.isEnabled = true
        rcc.skipForwardCommand.isEnabled = true
        rcc.stopCommand.isEnabled = false
        
    }

    @objc func skipBackwardEvent() {
        self.pvMediaPlayer.seek(toTime: self.pvMediaPlayer.progress - 15)
        MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.pvMediaPlayer.progress
    }
    
    @objc func skipForwardEvent() {
        self.pvMediaPlayer.seek(toTime: self.pvMediaPlayer.progress + 15)
        MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.pvMediaPlayer.progress
    }
    
    @objc func playOrPauseEvent() { 
        self.pvMediaPlayer.playOrPause()
        self.pvMediaPlayer.updateMPNowPlayingInfoCenter()
    }
    
    @objc func updatePlaybackPosition(event:MPChangePlaybackPositionCommandEvent) {
        self.pvMediaPlayer.seek(toTime: event.positionTime)
    }
    
}

