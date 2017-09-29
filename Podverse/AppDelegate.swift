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
    let playerHistoryManager = PlayerHistory.manager
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // Enable the media player to continue playing in the background and on the lock screen
        // Enable the media player to use remote control events
        // Remote control events are overridden in the AppDelegate and set in remoteControlReceivedWithEvent
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            do {
                try AVAudioSession.sharedInstance().setActive(true)
                UIApplication.shared.beginReceivingRemoteControlEvents()
            } catch let error as NSError {
                print(error.localizedDescription)
            }
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        
        UIApplication.shared.statusBarStyle = .lightContent
        setupUI()
        setupRemoteFunctions()
                
        // Ask for permission for Podverse to use push notifications
        application.registerUserNotificationSettings(UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil))  // types are UIUserNotificationType members
        application.beginBackgroundTask(withName: "showNotification", expirationHandler: nil)
        
        // Load the last playerHistoryItem in the media player if the user didn't finish listening to it
        playerHistoryManager.loadData()
        if let previousItem = playerHistoryManager.historyItems.first {
            if previousItem.hasReachedEnd != true {
                pvMediaPlayer.loadPlayerHistoryItem(item: previousItem)
            }            
        }
        
        PVAuth.shared.syncUserInfoWithServer()
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }

    func applicationWillTerminate(_ application: UIApplication) {
//        if pvMediaPlayer.audioPlayer.rate > 0.1 {
//            pvMediaPlayer.saveCurrentTimeAsPlaybackPosition()
//        }
        
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        return Lock.resumeAuth(url, options: options)
    }
    
//    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
  //      return A0Lock.shared().handle(url as URL, sourceApplication: sourceApplication)
    // }

    // func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
       // return A0Lock.shared().continue(userActivity, restorationHandler: restorationHandler)
    // }
    
    override func remoteControlReceived(with event: UIEvent?) {
        if let evt = event {
            pvMediaPlayer.remoteControlReceivedWithEvent(event: evt)
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
        pvMediaPlayer.seek(toTime: pvMediaPlayer.audioPlayer.progress - 15)
    }
    
    func skipForwardEvent() {
        pvMediaPlayer.seek(toTime: pvMediaPlayer.audioPlayer.progress + 15)
    }
    
    func playOrPauseEvent() {
        print("remote play or pause happened")
    }
}

