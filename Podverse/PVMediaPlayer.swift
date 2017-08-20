//
//  PVMediaPlayer.swift
//  Podverse
//
//  Created by Creon on 12/26/16.
//  Copyright © 2016 Podverse LLC. All rights reserved.
//

import Foundation
import AVFoundation
import MediaPlayer
import CoreData
import UIKit
import StreamingKit

extension Notification.Name {
    static let playerHasFinished = Notification.Name("playerHasFinished")
    static let playerIsLoading = Notification.Name("playerIsLoading")
    static let playerReadyToPlay = Notification.Name("playerReadyToPlay")
}

enum PlayingSpeed {
    case quarter, half, threeQuarts, regular, timeAndQuarter, timeAndHalf, double, doubleAndHalf
    
    var speedText:String {
        get {
            switch self {
            case .quarter:
                return ".25x"
            case .half:
                return ".5x"
            case .threeQuarts:
                return ".75x"
            case .regular:
                return "1x"
            case .timeAndQuarter:
                return "1.25x"
            case .timeAndHalf:
                return "1.5x"
            case .double:
                return "2x"
            case .doubleAndHalf:
                return "2.5x"
            }
        }
    }
    
    var speedValue:Float {
        get {
            switch self {
            case .quarter:
                return 0.25
            case .half:
                return 0.5
            case .threeQuarts:
                return 0.75
            case .regular:
                return 1
            case .timeAndQuarter:
                return 1.25
            case .timeAndHalf:
                return 1.5
            case .double:
                return 2
            case .doubleAndHalf:
                return 2.5
            }
        }
    }
}

protocol PVMediaPlayerUIDelegate {
    func mediaPlayerButtonStateChanged(showPlayerButton:Bool)
}

class PVMediaPlayer: NSObject {

    static let shared = PVMediaPlayer()
    
    var audioPlayer = STKAudioPlayer()
    var shouldEndAtTime: Int64?
    var nowPlayingItem:PlayerHistoryItem?
    var playerButtonDelegate:PVMediaPlayerUIDelegate?
    var playerHistoryManager = PlayerHistory.manager
    var shouldAutoplayAlways: Bool = false
    var shouldAutoplayOnce: Bool = false

    override init() {
        
        super.init()
        
        // Enable the media player to continue playing in the background and on the lock screen
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            do {
                try AVAudioSession.sharedInstance().setActive(true)
            } catch let error as NSError {
                print(error.localizedDescription)
            }
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        
        // Enable the media player to use remote control events
        // Remote control events are overridden in the AppDelegate and set in remoteControlReceivedWithEvent
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            UIApplication.shared.beginReceivingRemoteControlEvents()
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        
        setupObservers()
        
    }
    
    deinit {
        removeObservers()
    }
    
    func setupObservers () {
        self.addObserver(self, forKeyPath: #keyPath(audioPlayer.progress), options: .new, context: nil)
    }
    
    func removeObservers () {
        self.removeObserver(self, forKeyPath: #keyPath(audioPlayer.progress))
    }
    
    @objc func headphonesWereUnplugged(notification: Notification) {
        if let info = notification.userInfo {
            if let reasonKey = info[AVAudioSessionRouteChangeReasonKey] as? UInt {
                let reason = AVAudioSessionRouteChangeReason(rawValue: reasonKey)
                if reason == AVAudioSessionRouteChangeReason.oldDeviceUnavailable {
                    // Headphones were unplugged and AVPlayer has paused, so set the Play/Pause icon to Pause
                }
            }
        }
    }
    
    // TODO: should this be public here or not?
    @objc @discardableResult public func playOrPause() -> Bool {

        self.setPlayingInfo()
        
        let state = audioPlayer.state
        
        switch state {
        case STKAudioPlayerState.playing:
            audioPlayer.pause()
            return true
        default:
            audioPlayer.resume()
            return false
        }
        
    }
    
    func play() {
        audioPlayer.resume()
        shouldAutoplayOnce = false
    }
    
    func pause() {
        saveCurrentTimeAsPlaybackPosition()
        audioPlayer.pause()
    }
    
    @objc func playerDidFinishPlaying() {
        
        let moc = CoreDataHelper.createMOCForThread(threadType: .mainThread)
        if let nowPlayingItem = playerHistoryManager.historyItems.first, let episodeMediaUrl = nowPlayingItem.episodeMediaUrl, let episode = Episode.episodeForMediaUrl(mediaUrlString: episodeMediaUrl, managedObjectContext: moc) {
            PVDeleter.deleteEpisode(episodeId: episode.objectID, fileOnly: true, shouldCallNotificationMethod: true)
            nowPlayingItem.hasReachedEnd = true
            playerHistoryManager.addOrUpdateItem(item: nowPlayingItem)
        }
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .playerHasFinished, object: nil, userInfo: nil)
        }
        
    }

    func saveCurrentTimeAsPlaybackPosition() {
//        if let playingEpisode = self.nowPlayingEpisode {
//            let currentTime = NSNumber(value:CMTimeGetSeconds(avPlayer.currentTime()))
//            let didFinishPlaying = false // TODO
////            let playerHistoryItem = PlayerHistoryItem(itemId: playingEpisode.objectID, lastPlaybackPosition: currentTime, didFinishPlaying: didFinishPlaying, lastUpdated: Date())
////            playerHistoryManager.addOrUpdateItem(item: playerHistoryItem)
//            
//// TODO:playbackPosition
////            playingEpisode.playbackPosition = NSNumber(value: 100.5)
////            playingEpisode.managedObjectContext?.saveData(nil)
//        }
    }
    
    func remoteControlReceivedWithEvent(event: UIEvent) {
        if event.type == UIEventType.remoteControl {
//            if nowPlayingEpisode != nil || nowPlayingClip != nil {
//                switch event.subtype {
//                case UIEventSubtype.remoteControlPlay:
//                    self.playOrPause()
//                    break
//                case UIEventSubtype.remoteControlPause:
//                    self.playOrPause()
//                    break
//                case UIEventSubtype.remoteControlTogglePlayPause:
//                    self.playOrPause()
//                    break
//                default:
//                    break
//                }
//            }
        }
    }
    
    func setPlayingInfo() {
        
        guard let item =  self.nowPlayingItem else {
            return
        }
        
        var podcastTitle: String?
        var episodeTitle: String?
//        var podcastImage: MPMediaItemArtwork?
        var lastPlaybackTime: NSNumber?
        let rate = self.audioPlayer.rate
        
        if let pTitle = item.podcastTitle {
            podcastTitle = pTitle
        }
        
        if let eTitle = item.episodeTitle {
            episodeTitle = eTitle
        }
        
        let duration = self.audioPlayer.duration
        
        let lastPlaybackCMTime = self.audioPlayer.progress
        lastPlaybackTime = NSNumber(value: lastPlaybackCMTime)
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [MPMediaItemPropertyArtist: podcastTitle, MPMediaItemPropertyTitle: episodeTitle, MPMediaItemPropertyPlaybackDuration: duration, MPNowPlayingInfoPropertyElapsedPlaybackTime: lastPlaybackTime, MPNowPlayingInfoPropertyPlaybackRate: rate]
        
    }
    
    func clearPlayingInfo() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
    
    func loadPlayerHistoryItem(item: PlayerHistoryItem) {

        self.nowPlayingItem = item
        self.nowPlayingItem?.hasReachedEnd = false
        
        playerHistoryManager.addOrUpdateItem(item: nowPlayingItem)
        
        let moc = CoreDataHelper.createMOCForThread(threadType: .mainThread)
        
        if let episodeMediaUrlString = item.episodeMediaUrl, let episodeMediaUrl = URL(string: episodeMediaUrlString) {
            
            let episodesPredicate = NSPredicate(format: "mediaUrl == %@", episodeMediaUrlString)
            
            guard let episodes = CoreDataHelper.fetchEntities(className: "Episode", predicate: episodesPredicate, moc: moc) as? [Episode] else { return }
            
            // If the playerHistoryItems's episode is downloaded locally, then use it.
            if episodes.count > 0 {
                
                if let episode = episodes.first {
                    
                    var Urls = FileManager().urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask)
                    let docDirectoryUrl = Urls[0]
                    
                    if let fileName = episode.fileName {
                        
                        let destinationUrl = docDirectoryUrl.appendingPathComponent(fileName)
                        
                        let dataSource = STKAudioPlayer.dataSource(from: destinationUrl)
                        
                        self.audioPlayer.queue(dataSource, withQueueItemId: episodeMediaUrlString as NSObject)
                        
                    } else {

                        let dataSource = STKAudioPlayer.dataSource(from: episodeMediaUrl)
                        
                        self.audioPlayer.queue(dataSource, withQueueItemId: episodeMediaUrlString as NSObject)
                    }
                }
            }

            // Else remotely stream the whole episode.
            else {
                let dataSource = STKAudioPlayer.dataSource(from: episodeMediaUrl)
                
                self.audioPlayer.queue(dataSource, withQueueItemId: episodeMediaUrlString as NSObject)
            }
            
            if let startTime = item.startTime {
                self.audioPlayer.seek(toTime: Double(startTime))
            }
            
            if let endTime = item.endTime {
                self.shouldEndAtTime = endTime
            }
        }
        
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if (keyPath == "progress") {
            print("progress")
        }
        
    }
    
    @objc func playInterrupted(notification: NSNotification) {
//        if notification.name == NSNotification.Name.AVAudioSessionInterruption && notification.userInfo != nil {
//            var info = notification.userInfo!
//            var intValue: UInt = 0
//            
//            (info[AVAudioSessionInterruptionTypeKey] as! NSValue).getValue(&intValue)
//            
//            switch AVAudioSessionInterruptionType(rawValue: intValue) {
//                case .some(.began):
//                    saveCurrentTimeAsPlaybackPosition()
//                case .some(.ended):
//                    if mediaPlayerIsPlaying == true {
//                        playOrPause()
//                    }
//                default:
//                    break
//            }
//        }
    }
    
}
