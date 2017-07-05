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

protocol PVMediaPlayerDelegate {
//    func setMediaPlayerVCPlayPauseIcon()
//    func episodeFinishedPlaying(_ currentEpisode:Episode?)
//    func clipFinishedPlaying(_ currentClip:Clip?)
    
}

protocol PVMediaPlayerUIDelegate {
    func mediaPlayerButtonStateChanged(showPlayerButton:Bool)
}

class PVMediaPlayer {

    static let shared = PVMediaPlayer()
    var avPlayer = AVPlayer()
    var playerHistoryManager = PlayerHistory.manager
    var docDirectoryURL: URL?
    var currentlyPlayingItem:PlayerHistoryItem?

    var mediaPlayerIsPlaying = false
    var delegate: PVMediaPlayerDelegate?
    var playerButtonDelegate:PVMediaPlayerUIDelegate?
    var boundaryObserver:AnyObject?

    init() {
        
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: avPlayer.currentItem)
    }
    
    @objc func headphonesWereUnplugged(notification: Notification) {
        if let info = notification.userInfo {
            if let reasonKey = info[AVAudioSessionRouteChangeReasonKey] as? UInt {
                let reason = AVAudioSessionRouteChangeReason(rawValue: reasonKey)
                if reason == AVAudioSessionRouteChangeReason.oldDeviceUnavailable {
                    // Headphones were unplugged and AVPlayer has paused, so set the Play/Pause icon to Pause
                    DispatchQueue.main.async {
//                        self.delegate?.setMediaPlayerVCPlayPauseIcon()
                    }
                }
            }
        }
    }
    
    // TODO: should this be public here or not?
    @objc public func playOrPause() -> Bool {

        self.setPlayingInfo()
        
        if avPlayer.rate == 0 {
            avPlayer.play()
            mediaPlayerIsPlaying = true
//            self.delegate?.setMediaPlayerVCPlayPauseIcon()
            return true
            
        } else {
            saveCurrentTimeAsPlaybackPosition()
            avPlayer.pause()
            mediaPlayerIsPlaying = false
//            self.delegate?.setMediaPlayerVCPlayPauseIcon()
            return false
        }

//        self.delegate?.setMediaPlayerVCPlayPauseIcon()
        mediaPlayerIsPlaying = false
        return false
    }
    
    @objc func playerDidFinishPlaying() {
//        if nowPlayingClip == nil {
//            self.delegate?.episodeFinishedPlaying(nowPlayingEpisode)
//        } else {
//            self.delegate?.clipFinishedPlaying(nowPlayingClip)
//        }
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
//                    delegate?.setMediaPlayerVCPlayPauseIcon()
//                    break
//                case UIEventSubtype.remoteControlPause:
//                    self.playOrPause()
//                    delegate?.setMediaPlayerVCPlayPauseIcon()
//                    break
//                case UIEventSubtype.remoteControlTogglePlayPause:
//                    self.playOrPause()
//                    delegate?.setMediaPlayerVCPlayPauseIcon()
//                    break
//                default:
//                    break
//                }
//            }
        }
    }
    
    func setPlayingInfo() {
        guard let item =  currentlyPlayingItem else {
            return
        }
        
        var podcastTitle: String?
        var episodeTitle: String?
//        var podcastImage: MPMediaItemArtwork?
        var episodeDuration: NSNumber?
        var lastPlaybackTime: NSNumber?
        let rate = avPlayer.rate
        
        if let pTitle = item.podcastTitle {
            podcastTitle = pTitle
        }
        
        if let eTitle = item.episodeTitle {
            episodeTitle = eTitle
        }
        
//        if let podcastiTunesImageData = episode.podcast.itunesImage {
//            let podcastiTunesImage = UIImage(data: podcastiTunesImageData)
//            podcastImage = MPMediaItemArtwork(image: podcastiTunesImage!)
//        } else if let podcastImageData = episode.podcast.imageData {
//            let podcastImage = UIImage(data: podcastImageData)
//            podcastImage = MPMediaItemArtwork(image: podcastImage!)
//        } else {
//            podcastImage = MPMediaItemArtwork(image: UIImage(named: "PodverseIcon")!)
//        }

        if let eDuration = item.episodeDuration {
            episodeDuration = eDuration as NSNumber
        }
        
        let lastPlaybackCMTime = CMTimeGetSeconds(avPlayer.currentTime())
        lastPlaybackTime = NSNumber(value: lastPlaybackCMTime)
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [MPMediaItemPropertyArtist: podcastTitle, MPMediaItemPropertyTitle: episodeTitle, MPMediaItemPropertyPlaybackDuration: episodeDuration, MPNowPlayingInfoPropertyElapsedPlaybackTime: lastPlaybackTime, MPNowPlayingInfoPropertyPlaybackRate: rate]
        
        //        MPNowPlayingInfoCenter.default().nowPlayingInfo = [MPMediaItemPropertyArtist: podcastTitle, MPMediaItemPropertyTitle: episodeTitle, MPMediaItemPropertyArtwork: mpImage, MPMediaItemPropertyPlaybackDuration: mpDuration, MPNowPlayingInfoPropertyElapsedPlaybackTime: mpElapsedPlaybackTime, MPNowPlayingInfoPropertyPlaybackRate: mpRate]
    }
    
    func clearPlayingInfo() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
    
    func goToTime(seconds: Double) {
        avPlayer.seek(to: CMTimeMakeWithSeconds(seconds, 1))
    }
        
    func loadPlayerHistoryItem(playerHistoryItem: PlayerHistoryItem) {
        if avPlayer.rate == 1 {
            saveCurrentTimeAsPlaybackPosition()
        }
        
        currentlyPlayingItem = playerHistoryItem
        
        avPlayer.replaceCurrentItem(with: nil)
        
        let moc = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        moc.parent = CoreDataHelper.shared.managedObjectContext
        
        if let episodeMediaUrl = playerHistoryItem.episodeMediaUrl {
            playerHistoryManager.addOrUpdateItem(item: playerHistoryItem)
            
            let episodesPredicate = NSPredicate(format: "mediaUrl == %@", episodeMediaUrl)
            if let episodes = CoreDataHelper.fetchEntities(className: "Episode", predicate: episodesPredicate, moc: moc) as? [Episode] {
                if let episode = episodes.first {
                    var URLs = FileManager().urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask)
                    self.docDirectoryURL = URLs[0]
                    
                    if let fileName = episode.fileName, let destinationUrl = self.docDirectoryURL?.appendingPathComponent(fileName) {
                        let playerItem = AVPlayerItem(url: destinationUrl)
                        avPlayer.replaceCurrentItem(with: playerItem)
                        
                        // Remember the downloaded episode loaded in media player so if the app closes while the episode is playing or paused, it can be reloaded on app launch.
                        UserDefaults.standard.set(episode.objectID.uriRepresentation(), forKey: kLastPlayingEpisodeURL)
                        
                    } else {
                        if let urlString = currentlyPlayingItem?.episodeMediaUrl, let url = NSURL(string: urlString) {
                            let playerItem = AVPlayerItem(url: url as URL)
                            avPlayer.replaceCurrentItem(with: playerItem)
                        }
                    }
                }
            } else {
                if let urlString = currentlyPlayingItem?.episodeMediaUrl, let url = NSURL(string: urlString) {
                    let playerItem = AVPlayerItem(url: url as URL)
                    avPlayer.replaceCurrentItem(with: playerItem)
                }
            }
        }
        
    }
        
    func loadClipToPlay(clipID: NSManagedObjectID) {
        let moc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        moc.parent = CoreDataHelper.shared.managedObjectContext
        
        moc.refreshAllObjects()
        
//        nowPlayingClip = CoreDataHelper.fetchEntityWithID(objectId: clipID, moc: moc) as? Clip
//        guard let nowPlayingClip = self.nowPlayingClip else{
//            return
//        }
//        
//        nowPlayingEpisode = CoreDataHelper.fetchEntityWithID(objectId: nowPlayingClip.episode.objectID, moc: moc) as? Episode
        // TODO:
        avPlayer.replaceCurrentItem(with: nil)
        //        if nowPlayingEpisode.fileName != nil {
        //            var URLs = NSFileManager().URLsForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask)
        //            self.docDirectoryURL = URLs[0]
        //
        //            if let fileName = nowPlayingEpisode.fileName, let destinationURL = self.docDirectoryURL?.URLByAppendingPathComponent(fileName) {
        //                let playerItem = AVPlayerItem(URL: destinationURL)
        //                avPlayer = AVPlayer(playerItem: playerItem)
        //
        //                let endTime = CMTimeMakeWithSeconds(Double(clip.endTime!), 1)
        //                let endTimeValue = NSValue(CMTime: endTime)
        //                self.boundaryObserver = avPlayer.addBoundaryTimeObserverForTimes([endTimeValue], queue: nil, usingBlock: {
        //                    self.playOrPause()
        //                    if let observer = self.boundaryObserver{
        //                        self.avPlayer.removeTimeObserver(observer)
        //                    }
        //                })
        //
        //                goToTime(Double(clip.startTime))
        //            }
        //        } else {
        
//        PVClipStreamer.shared.streamClip(clip: nowPlayingClip)
        playOrPause()
        //        }

        self.setPlayingInfo()
    }
    
    @objc func playInterrupted(notification: NSNotification) {
        if notification.name == NSNotification.Name.AVAudioSessionInterruption && notification.userInfo != nil {
            var info = notification.userInfo!
            var intValue: UInt = 0
            
            (info[AVAudioSessionInterruptionTypeKey] as! NSValue).getValue(&intValue)
            
            switch AVAudioSessionInterruptionType(rawValue: intValue) {
                case .some(.began):
                    saveCurrentTimeAsPlaybackPosition()
                case .some(.ended):
                    if mediaPlayerIsPlaying == true {
                        playOrPause()
                    }
                default:
                    break
            }
        }
    }
}



