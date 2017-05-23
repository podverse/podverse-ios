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
    case Quarter, Half, ThreeQuarts, Regular, TimeAndQuarter, TimeAndHalf, Double, DoubleAndHalf
    
    var speedText:String {
        get {
            switch self {
            case .Quarter:
                return "X .25"
            case .Half:
                return "X .5"
            case .ThreeQuarts:
                return "X .75"
            case .Regular:
                return ""
            case .TimeAndQuarter:
                return "X 1.25"
            case .TimeAndHalf:
                return "X 1.5"
            case .Double:
                return "X 2"
            case .DoubleAndHalf:
                return "X 2.5"
            }
        }
    }
    
    var speedVaue:Float {
        get {
            switch self {
            case .Quarter:
                return 0.25
            case .Half:
                return 0.5
            case .ThreeQuarts:
                return 0.75
            case .Regular:
                return 1
            case .TimeAndQuarter:
                return 1.25
            case .TimeAndHalf:
                return 1.5
            case .Double:
                return 2
            case .DoubleAndHalf:
                return 2.5
            }
        }
    }
}

protocol PVMediaPlayerDelegate {
    func setMediaPlayerVCPlayPauseIcon()
    func episodeFinishedPlaying(_ currentEpisode:Episode?)
    func clipFinishedPlaying(_ currentClip:Clip?)
    
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
                        self.delegate?.setMediaPlayerVCPlayPauseIcon()
                    }
                }
            }
        }
    }
    
    @discardableResult func playOrPause() -> Bool {
        if avPlayer.currentItem != nil {
            self.setPlayingInfo()
            
            if avPlayer.rate == 0 {
                avPlayer.play()
                mediaPlayerIsPlaying = true
                self.delegate?.setMediaPlayerVCPlayPauseIcon()
                return true
                
            } else {
                saveCurrentTimeAsPlaybackPosition()
                avPlayer.pause()
                mediaPlayerIsPlaying = false
                self.delegate?.setMediaPlayerVCPlayPauseIcon()
                return false
            }
        }
        self.delegate?.setMediaPlayerVCPlayPauseIcon()
        mediaPlayerIsPlaying = false
        return false
    }
    
    @objc func playerDidFinishPlaying() {
        if nowPlayingClip == nil {
            self.delegate?.episodeFinishedPlaying(nowPlayingEpisode)
        } else {
            self.delegate?.clipFinishedPlaying(nowPlayingClip)
        }
    }

    func saveCurrentTimeAsPlaybackPosition() {
        if let playingEpisode = self.nowPlayingEpisode {
            let currentTime = NSNumber(value:CMTimeGetSeconds(avPlayer.currentTime()))
            let didFinishPlaying = false // TODO
//            let playerHistoryItem = PlayerHistoryItem(itemId: playingEpisode.objectID, lastPlaybackPosition: currentTime, didFinishPlaying: didFinishPlaying, lastUpdated: Date())
//            playerHistoryManager.addOrUpdateItem(item: playerHistoryItem)
            
// TODO:playbackPosition
//            playingEpisode.playbackPosition = NSNumber(value: 100.5)
//            playingEpisode.managedObjectContext?.saveData(nil)
        }
    }
    
    func remoteControlReceivedWithEvent(event: UIEvent) {
        if event.type == UIEventType.remoteControl {
            if nowPlayingEpisode != nil || nowPlayingClip != nil {
                switch event.subtype {
                case UIEventSubtype.remoteControlPlay:
                    self.playOrPause()
                    delegate?.setMediaPlayerVCPlayPauseIcon()
                    break
                case UIEventSubtype.remoteControlPause:
                    self.playOrPause()
                    delegate?.setMediaPlayerVCPlayPauseIcon()
                    break
                case UIEventSubtype.remoteControlTogglePlayPause:
                    self.playOrPause()
                    delegate?.setMediaPlayerVCPlayPauseIcon()
                    break
                default:
                    break
                }
            }
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
        let resultTime = CMTimeMakeWithSeconds(seconds, 1)
        let currentRate = avPlayer.rate
        avPlayer.pause()
        avPlayer.seek(to: resultTime)
        saveCurrentTimeAsPlaybackPosition()
        avPlayer.rate = currentRate
        avPlayer.play()
        mediaPlayerIsPlaying = true
        self.delegate?.setMediaPlayerVCPlayPauseIcon()
    }
    
    func skipTime(seconds: Double) {
        let currentTime = avPlayer.currentTime()
        let timeAdjust = CMTimeMakeWithSeconds(seconds, 1)
        let resultTime = CMTimeAdd(currentTime, timeAdjust)
        let currentRate = avPlayer.rate
        avPlayer.pause()
        avPlayer.seek(to: resultTime)
        saveCurrentTimeAsPlaybackPosition()
        avPlayer.play()
        avPlayer.rate = currentRate
        mediaPlayerIsPlaying = true
    }
    
    func previousTime(seconds: Double) {
        let currentTime = avPlayer.currentTime()
        let timeAdjust = CMTimeMakeWithSeconds(seconds, 1)
        let resultTime = CMTimeSubtract(currentTime, timeAdjust)
        let currentRate = avPlayer.rate
        avPlayer.pause()
        avPlayer.seek(to: resultTime)
        saveCurrentTimeAsPlaybackPosition()
        avPlayer.play()
        avPlayer.rate = currentRate
        mediaPlayerIsPlaying = true
    }
    
    func loadPlayerHistoryItem(playerHistoryItem: PlayerHistoryItem) {
        avPlayer.replaceCurrentItem(with: nil)
        
        let moc = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        moc.parent = CoreDataHelper.shared.managedObjectContext
        
        let episodesPredicate = NSPredicate(format: "episodeMediaUrl == YES")
        let podcastArray = CoreDataHelper.fetchEntities(className:"Podcast", predicate: podcastsPredicate, moc:moc) as! [Podcast]
        
        for podcast in podcastArray {
            parsingPodcasts.urls.append(podcast.feedURL)
            let feedURL = NSURL(string:podcast.feedURL)
            
            let feedParser = PVFeedParser(shouldOnlyGetMostRecentEpisode: true, shouldSubscribe:false, shouldFollowPodcast: false, shouldOnlyParseChannel: false)
            feedParser.delegate = self
            if let feedURLString = feedURL?.absoluteString {
                feedParser.parsePodcastFeed(feedURLString: feedURLString)
                self.updateParsingActivity()
            }
        }
        
        
        
        
        if playerHistoryItem.fileName != nil {
            var Urls = FileManager().urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask)
        }
        
        if nowPlayingEpisode?.fileName != nil {
            var URLs = FileManager().urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask)
            self.docDirectoryURL = URLs[0]
            
            if let fileName = nowPlayingEpisode?.fileName, let destinationURL = self.docDirectoryURL?.appendingPathComponent(fileName) {
                let playerItem = AVPlayerItem(url: destinationURL)
                avPlayer.replaceCurrentItem(with: playerItem)
                
                // Remember the downloaded episode loaded in media player so, if the app closes while the episode is playing or paused, it can be reloaded on app launch.
                UserDefaults.standard.set(nowPlayingEpisode?.objectID.uriRepresentation(), forKey: kLastPlayingEpisodeURL)
            }
        } else {
            if let urlString = nowPlayingEpisode?.mediaURL, let url = NSURL(string: urlString) {
                let playerItem = AVPlayerItem(url: url as URL)
                avPlayer.replaceCurrentItem(with: playerItem)
            }
        }
        
    }

    func loadEpisodeDownloadedMediaFileOrStream(episodeID: NSManagedObjectID, paused: Bool) {
        

        
        if paused == false {
            // If the episode has a playback position, then continue from that point, else play from the beginning
            // TODO:playbackPosition
//            if let playbackPosition = nowPlayingEpisode?.playbackPosition {
//                goToTime(seconds: Double(playbackPosition))
//            } else {
//                playOrPause()
//            }
        } else {
            // If the episode should be loaded and paused, then seek to the playbackPosition without playing
// TODO:playbackPosition
//            if let playbackPosition = nowPlayingEpisode?.playbackPosition {
//                let resultTime = CMTimeMakeWithSeconds(Double(playbackPosition), 1)
//                avPlayer.seek(to: resultTime)
//            }
        }
        
//        self.setPlayingInfo()
    }
    
    func loadClipToPlay(clipID: NSManagedObjectID) {
        let moc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        moc.parent = CoreDataHelper.shared.managedObjectContext
        
        moc.refreshAllObjects()
        
        nowPlayingClip = CoreDataHelper.fetchEntityWithID(objectId: clipID, moc: moc) as? Clip
        guard let nowPlayingClip = self.nowPlayingClip else{
            return
        }
        
        nowPlayingEpisode = CoreDataHelper.fetchEntityWithID(objectId: nowPlayingClip.episode.objectID, moc: moc) as? Episode
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
        
        PVClipStreamer.shared.streamClip(clip: nowPlayingClip)
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



