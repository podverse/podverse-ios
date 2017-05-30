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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var backgroundTransferCompletionHandler: (() -> Void)?
    var timer: DispatchSource!
    let pvMediaPlayer = PVMediaPlayer.shared
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        A0Lock.shared().applicationLaunched(options: launchOptions)
        UIApplication.shared.statusBarStyle = .lightContent
        setupUI()
        setupRemoteFunctions()
        
        // Ask for permission for Podverse to use push notifications
        application.registerUserNotificationSettings(UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil))  // types are UIUserNotificationType members
        application.beginBackgroundTask(withName: "showNotification", expirationHandler: nil)
        
        CoreDataHelper.resetEpisodesState()
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
//        if let _ = PVMediaPlayer.shared.nowPlayingEpisode {
//            PVMediaPlayer.shared.setPlayingInfo()
//        }
        
        UIApplication.shared.applicationIconBadgeNumber = 0
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }

    func applicationWillTerminate(_ application: UIApplication) {
        if PVMediaPlayer.shared.avPlayer.rate == 1 {
            PVMediaPlayer.shared.saveCurrentTimeAsPlaybackPosition()
        }
        
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return A0Lock.shared().handle(url as URL, sourceApplication: sourceApplication)
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        return A0Lock.shared().continue(userActivity, restorationHandler: restorationHandler)
    }
    
    override func remoteControlReceived(with event: UIEvent?) {
        if let evt = event {
            PVMediaPlayer.shared.remoteControlReceivedWithEvent(event: evt)
        }
    }
    
    fileprivate func setupUI() {
        UINavigationBar.appearance().isTranslucent = false
        UINavigationBar.appearance().barTintColor = UIColor(red: 41.0/255.0, green: 104.0/255.0, blue: 177.0/255.0, alpha: 1.0)
        UINavigationBar.appearance().tintColor = UIColor.white
        UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white, NSFontAttributeName: UIFont.boldSystemFont(ofSize: 17.0)]
    }
    
    fileprivate func setupRemoteFunctions() {
        // Add skip or back 15 seconds to the lock screen media player
        let rcc = MPRemoteCommandCenter.shared()
        
        let skipBackwardIntervalCommand = rcc.skipBackwardCommand
        skipBackwardIntervalCommand.addTarget(self, action: #selector(AppDelegate.skipBackwardEvent))
        
        let skipForwardIntervalCommand = rcc.skipForwardCommand
        skipForwardIntervalCommand.addTarget(self, action: #selector(AppDelegate.skipForwardEvent))
        
        let pauseCommand = rcc.pauseCommand
        pauseCommand.addTarget(self, action: #selector(AppDelegate.playOrPauseEvent))
        let playCommand = rcc.playCommand
        playCommand.addTarget(self, action: #selector(AppDelegate.playOrPauseEvent))
    }

    func skipBackwardEvent() {
        if let currentItem = pvMediaPlayer.avPlayer.currentItem {
            pvMediaPlayer.goToTime(seconds: CMTimeGetSeconds(currentItem.currentTime()) - 15)
        }
        pvMediaPlayer.setPlayingInfo()
    }
    
    func skipForwardEvent() {
        if let currentItem = pvMediaPlayer.avPlayer.currentItem {
            pvMediaPlayer.goToTime(seconds: CMTimeGetSeconds(currentItem.currentTime()) + 15)
        }
        pvMediaPlayer.setPlayingInfo()
    }
    
    func playOrPauseEvent() {
        print("remote play or pause happened")
    }
}

