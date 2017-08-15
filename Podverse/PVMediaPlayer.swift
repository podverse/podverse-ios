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
    
    var speedVaue:Float {
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
    var avPlayer = AVPlayer()
    var boundaryObserver:Any?
    var docDirectoryURL: URL?
    var mediaPlayerIsPlaying = false
    var nowPlayingClipStartTime: Int64?
    var nowPlayingClipEndTime: Int64?
    var nowPlayingItem:PlayerHistoryItem?
    var nowPlayingPlaybackPosition = Int64(0)
    var playerButtonDelegate:PVMediaPlayerUIDelegate?
    var playerHistoryManager = PlayerHistory.manager
    let pvStreamer = PVStreamer.shared
    var shouldAutoplayAlways: Bool = false
    var shouldAutoplayOnce: Bool = false
    var shouldStreamOnlyRange: Bool = false

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
        
        NotificationCenter.default.addObserver(self, selector: #selector(playInterrupted(notification:)), name: NSNotification.Name.AVAudioSessionInterruption, object: AVAudioSession.sharedInstance())
        
        NotificationCenter.default.addObserver(self, selector: #selector(headphonesWereUnplugged(notification:)), name: NSNotification.Name.AVAudioSessionRouteChange, object: AVAudioSession.sharedInstance())
        
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
        
        if avPlayer.rate == 0 {
            play()
            
            // If only streaming a clip range, and the avPlayer is ready to play, but the player's current time is within 3 seconds of the end of the clip, then assume the player has finished playing the clip and trigger streaming the full episode remotely.
            if self.shouldStreamOnlyRange == true && self.avPlayer.status.rawValue == 1 && self.avPlayer.currentItem?.status.rawValue == 1 {
                
                guard let item = self.nowPlayingItem else { return false }
                guard let currentTime = self.avPlayer.currentItem?.currentTime() else { return false }
                guard let startTime = item.startTime else { return false }
                guard let endTime = item.endTime else { return false }
                
                let time = Int64(CMTimeGetSeconds(currentTime)) + startTime
                
                if time - 3 > endTime {
                    loadPlayerHistoryItem(item: item, forceFullStream: true)
                }
                
            }
            
            return true
            
        } else {
            pause()
            return false
        }

    }
    
    func play() {
        avPlayer.play()
        mediaPlayerIsPlaying = true
        shouldAutoplayOnce = false
    }
    
    func pause() {
        saveCurrentTimeAsPlaybackPosition()
        avPlayer.pause()
        mediaPlayerIsPlaying = false
    }
    
    @objc func playerDidFinishPlaying() {
        
        if !self.shouldStreamOnlyRange {
            let moc = CoreDataHelper.createMOCForThread(threadType: .mainThread)
            if let nowPlayingItem = playerHistoryManager.historyItems.first, let episodeMediaUrl = nowPlayingItem.episodeMediaUrl, let episode = Episode.episodeForMediaUrl(mediaUrlString: episodeMediaUrl, managedObjectContext: moc) {
                PVDeleter.deleteEpisode(episodeId: episode.objectID, fileOnly: true, shouldCallNotificationMethod: true)
                nowPlayingItem.hasReachedEnd = true
                playerHistoryManager.addOrUpdateItem(item: nowPlayingItem)
            }
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
        
        guard let item =  nowPlayingItem else {
            return
        }
        
        var podcastTitle: String?
        var episodeTitle: String?
//        var podcastImage: MPMediaItemArtwork?
        var lastPlaybackTime: NSNumber?
        let rate = avPlayer.rate
        
        if let pTitle = item.podcastTitle {
            podcastTitle = pTitle
        }
        
        if let eTitle = item.episodeTitle {
            episodeTitle = eTitle
        }
        
        let episodeDuration = self.avPlayer.currentItem?.asset.duration
        
        let lastPlaybackCMTime = CMTimeGetSeconds(avPlayer.currentTime())
        lastPlaybackTime = NSNumber(value: lastPlaybackCMTime)
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [MPMediaItemPropertyArtist: podcastTitle, MPMediaItemPropertyTitle: episodeTitle, MPMediaItemPropertyPlaybackDuration: episodeDuration, MPNowPlayingInfoPropertyElapsedPlaybackTime: lastPlaybackTime, MPNowPlayingInfoPropertyPlaybackRate: rate]
        
    }
    
    func clearPlayingInfo() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
    
    func goToTime(seconds: Double, timePercent: Float? = nil) {
        
        var sec = Float(seconds)
        
        if let timePercent = timePercent {
            if self.shouldStreamOnlyRange {
                if let time = self.nowPlayingClipStartTime {
                    sec = timePercent * Float(pvStreamer.currentFullDuration)
                }
            } else {
                if let item = self.avPlayer.currentItem {
                    let duration = Float(CMTimeGetSeconds(item.duration))
                    sec = timePercent * duration
                }
            }
        } else {
            if self.shouldStreamOnlyRange {
                if let time = self.nowPlayingClipStartTime {
                    sec = sec + Float(time)
                }
            }
        }
        
        if self.shouldStreamOnlyRange && !self.pvStreamer.checkIfCurrentTimeIsWithinStreamRange(currentTime: Int(sec)) {
            if let item = self.nowPlayingItem?.convertClipToEpisode() {
                loadPlayerHistoryItem(item: item, startTime: Int64(sec))
            }
            
        } else if self.shouldStreamOnlyRange {
            if let startTime = self.nowPlayingClipStartTime {
                let adjustedCurrentTime = Int64(sec) - startTime
                self.avPlayer.seek(to: CMTimeMakeWithSeconds(Float64(adjustedCurrentTime), 1))
            }
            
        } else {
            self.shouldStreamOnlyRange = false
            self.avPlayer.seek(to: CMTimeMakeWithSeconds(Double(sec), 1))
        }
        
    }
        
    func loadPlayerHistoryItem(item: PlayerHistoryItem, startTime: Int64? = nil, forceFullStream: Bool = false) {

        self.nowPlayingPlaybackPosition = startTime ?? item.startTime ?? Int64(0)
        self.nowPlayingClipStartTime = item.startTime
        self.nowPlayingClipEndTime = item.endTime
        
        // If the playerHistoryItem's episode is already playing in full, then only adjust the player position and set the clip end observer if available.
        if self.nowPlayingItem?.episodeMediaUrl == item.episodeMediaUrl && !self.shouldStreamOnlyRange {
            
            self.nowPlayingItem = item
            self.nowPlayingItem?.hasReachedEnd = false
            
            playerHistoryManager.addOrUpdateItem(item: self.nowPlayingItem)
            
            self.goToTime(seconds: Double(self.nowPlayingPlaybackPosition))
            
            if let endTime = nowPlayingClipEndTime {
                self.boundaryObserver = self.avPlayer.addBoundaryTimeObserver(forTimes: [endTime as NSValue], queue: nil, using: {
                    self.playOrPause()
                    
                    if let observer = self.boundaryObserver {
                        self.avPlayer.removeTimeObserver(observer)
                    }
                })
            }
            
        }
        else {
            
            self.shouldStreamOnlyRange = item.isClip()
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .playerIsLoading, object: nil, userInfo: nil)
            }
            
            nowPlayingItem = item
            nowPlayingItem?.hasReachedEnd = false
            
            playerHistoryManager.addOrUpdateItem(item: nowPlayingItem)
            
            if let observer = self.boundaryObserver {
                self.avPlayer.removeTimeObserver(observer)
            }
            
            avPlayer.currentItem?.removeObserver(self, forKeyPath: "status", context: nil)
            avPlayer.replaceCurrentItem(with: nil)
            
            let moc = CoreDataHelper.createMOCForThread(threadType: .mainThread)
            
            if let episodeMediaUrlString = item.episodeMediaUrl, let episodeMediaUrl = URL(string: episodeMediaUrlString) {
                
                let episodesPredicate = NSPredicate(format: "mediaUrl == %@", episodeMediaUrlString)
                
                guard let episodes = CoreDataHelper.fetchEntities(className: "Episode", predicate: episodesPredicate, moc: moc) as? [Episode] else { return }
                
                // If the playerHistoryItems's episode is downloaded locally, then use it.
                if episodes.count > 0 {
                    self.shouldStreamOnlyRange = false
                    
                    if let episode = episodes.first {
                        
                        var URLs = FileManager().urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask)
                        self.docDirectoryURL = URLs[0]
                        
                        if let fileName = episode.fileName, let destinationUrl = self.docDirectoryURL?.appendingPathComponent(fileName) {
                            let playerItem = AVPlayerItem(url: destinationUrl)
                            self.avPlayer.replaceCurrentItem(with: playerItem)
                            self.avPlayer.currentItem?.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions(), context: nil)
                        } else {
                            if let urlString = nowPlayingItem?.episodeMediaUrl, let url = NSURL(string: urlString) {
                                let playerItem = AVPlayerItem(url: url as URL)
                                self.avPlayer.replaceCurrentItem(with: playerItem)
                                self.avPlayer.currentItem?.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions(), context: nil)
                            }
                        }
                        
                    }
                }
                // Else if the playerHistoryItem is a clip, then remotely stream just the clip byte range.
                else if self.shouldStreamOnlyRange && !forceFullStream {
                    DispatchQueue.global().async {
                        if let playerItem = self.pvStreamer.prepareAsset(item: item) {
                            self.avPlayer.replaceCurrentItem(with: playerItem)
                            self.avPlayer.currentItem?.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions(), context: nil)
                        }
                    }
                }
                // Else remotely stream the whole episode.
                else {
                    self.shouldStreamOnlyRange = false
                    let playerItem = AVPlayerItem(url: episodeMediaUrl)
                    self.avPlayer.replaceCurrentItem(with: playerItem)
                    self.avPlayer.currentItem?.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions(), context: nil)
                }
                
                NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: avPlayer.currentItem)
                
            }
            
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
    
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if let currentItem = object as? AVPlayerItem {
            
            if currentItem.status == AVPlayerItemStatus.readyToPlay {
                print("ready 2 play :D")
                
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .playerReadyToPlay, object: nil, userInfo: nil)
                }
                
                if !self.shouldStreamOnlyRange {
                    goToTime(seconds: Double(self.nowPlayingPlaybackPosition))

                    if let time = self.nowPlayingClipEndTime {
                        
                        if let observer = self.boundaryObserver {
                            self.avPlayer.removeTimeObserver(observer)
                        }
                        
                        self.boundaryObserver = self.avPlayer.addBoundaryTimeObserver(forTimes: [time as NSValue], queue: nil, using: {
                            self.playOrPause()
                            if let observer = self.boundaryObserver {
                                self.avPlayer.removeTimeObserver(observer)
                            }
                        })
                    }
                }
                
                if self.shouldAutoplayOnce || self.shouldAutoplayAlways {
                    self.play()
                }
                
            } else if currentItem.status == AVPlayerItemStatus.failed {
                print("errrrroorrrrr")
            }
            
        }
        
    }
    
}
