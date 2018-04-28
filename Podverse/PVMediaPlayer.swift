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
    static let hideClipData = Notification.Name("hideClipData")
    static let playerHasFinished = Notification.Name("playerHasFinished")
}

enum PlayingSpeed {
    case half, threeQuarts, regular, timeAndQuarter, timeAndHalf, double
    
    var speedText:String {
        get {
            switch self {
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
            }
        }
    }
    
    var speedValue:Float {
        get {
            switch self {
            case .half:
                return 0.5
            case .threeQuarts:
                return 0.75
            case .regular:
                return 1.0
            case .timeAndQuarter:
                return 1.25
            case .timeAndHalf:
                return 1.5
            case .double:
                return 2.0
            }
        }
    }
    
}

protocol PVMediaPlayerUIDelegate {
    func playerHistoryItemBuffering()
    func playerHistoryItemErrored()
    func playerHistoryItemLoaded()
    func playerHistoryItemLoadingBegan()
    func playerHistoryItemPaused()
}

class PVMediaPlayer:NSObject {

    static let shared = PVMediaPlayer()
    
    // TODO: should this be on the main thread??
    let moc = CoreDataHelper.createMOCForThread(threadType: .mainThread)
    
    var audioPlayer = STKAudioPlayer()
    var clipTimer: Timer?
    var playbackTimer: Timer?
    var duration: Double?
    var isItemLoaded = false
    var nowPlayingItem:PlayerHistoryItem?
    var delegate:PVMediaPlayerUIDelegate?
    var playerHistoryManager = PlayerHistory.manager
    var shouldAutoplayAlways: Bool = false
    var shouldAutoplayOnce: Bool = false
    var shouldHideClipDataNextPlay:Bool = false
    var shouldSetupClip: Bool = false
    var shouldStartFromTime: Int64 = 0
    var shouldStopAtEndTime: Int64 = 0
    var hasErrored: Bool = false
    
    var playerSpeedRate:PlayingSpeed = .regular {
        didSet {
            self.audioPlayer.rate = playerSpeedRate.speedValue
        }
    }
    
    var progress:Double {
        return self.audioPlayer.duration > 0 ? self.audioPlayer.progress : Double(self.shouldStartFromTime)
    }

    override init() {
        super.init()
        self.audioPlayer.delegate = self
        addObservers()
        startClipTimer()
        startPlaybackTimer()
    }
    
    deinit {
        removeObservers()
        removeClipTimer()
        removePlaybackTimer()
    }
    
    @objc func headphonesWereUnplugged(notification: Notification) {
        if let info = notification.userInfo {
            if let reasonKey = info[AVAudioSessionRouteChangeReasonKey] as? UInt {
                let reason = AVAudioSessionRouteChangeReason(rawValue: reasonKey)
                if reason == AVAudioSessionRouteChangeReason.oldDeviceUnavailable {
                    // Headphones were unplugged, so the media player should pause
                    pause()
                }
            }
        }
    }
    
    private func startClipTimer () {
        self.clipTimer = Timer.scheduledTimer(timeInterval: 0.25, target: self, selector: #selector(stopAtEndTime), userInfo: nil, repeats: true)
    }
    
    private func removeClipTimer () {
        if let timer = self.clipTimer {
            timer.invalidate()
        }
    }
    
    private func startPlaybackTimer () {
        self.playbackTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(savePlaybackPosition), userInfo: nil, repeats: true)
    }
    
    private func removePlaybackTimer () {
        if let timer = self.playbackTimer {
            timer.invalidate()
        }
    }
    
    @objc func savePlaybackPosition() {
        if let item = nowPlayingItem, self.progress > 0 {
            item.lastPlaybackPosition = Int64(self.progress)
            self.shouldStartFromTime = Int64(self.progress)
            playerHistoryManager.addOrUpdateItem(item: item)
        }
    }
    
    private func clearPlaybackPosition() {
        if let item = nowPlayingItem, self.progress > 0 {
            item.lastPlaybackPosition = Int64(0)
            self.playerHistoryManager.addOrUpdateItem(item: item)
        }
    }
    
    fileprivate func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(headphonesWereUnplugged), name: .AVAudioSessionRouteChange, object: AVAudioSession.sharedInstance())
        NotificationCenter.default.addObserver(self, selector: #selector(playInterrupted), name: .AVAudioSessionInterruption, object: AVAudioSession.sharedInstance())
    }
    
    fileprivate func removeObservers() {
        NotificationCenter.default.removeObserver(self, name: .AVAudioSessionRouteChange, object: AVAudioSession.sharedInstance())
        NotificationCenter.default.removeObserver(self, name: .AVAudioSessionInterruption, object: AVAudioSession.sharedInstance())
    }
    
    @objc private func stopAtEndTime() {
        
        if self.shouldStopAtEndTime > 0 && Int64(self.audioPlayer.progress) > self.shouldStopAtEndTime {
            self.pause()
            self.shouldHideClipDataNextPlay = true
            self.shouldStartFromTime = 0
        }
        
    }
    
    // TODO: should this be public here or not?
    @objc @discardableResult public func playOrPause() -> Bool {
        
        let state = audioPlayer.state
        
        // If a clip has reached or exceeded it's end time playback position, the clip data will stay in the UI, the player will pause, and the next time the player attempts to play a Notification is dispatched telling the VCs to hide the clip data.
        if self.shouldHideClipDataNextPlay && !isInClipTimeRange(), let item = self.nowPlayingItem {
            item.removeClipData()
            
            self.shouldStopAtEndTime = 0
            self.shouldHideClipDataNextPlay = false
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .hideClipData, object: nil, userInfo: nil)
            }
        }
        
        // If nothing loaded in the player, but playOrPause was pressed, then attempt to load and play the file.
        if !playerIsLoaded() {
            self.shouldAutoplayOnce = true
            if let item = self.nowPlayingItem {
                self.loadPlayerHistoryItem(item: item)
            }
            return true
        }
        
        switch state {
        case STKAudioPlayerState.playing:
            self.pause()
            return true
        default:
            self.play()
            return false
        }
        
    }
    
    func playerIsLoaded() -> Bool {
        let state = audioPlayer.state
        
        if state == STKAudioPlayerState.disposed || state == STKAudioPlayerState.error || state == STKAudioPlayerState.stopped {
            return false
        } else {
            return true
        }
    }
    
    func toggleShouldPlayContinuously () {
        let currentValue = UserDefaults.standard.bool(forKey: kShouldPlayContinuously)
        UserDefaults.standard.set(!currentValue, forKey: kShouldPlayContinuously)
    }
    
    func seek(toTime: Double) {
        self.shouldStartFromTime = Int64(toTime)
        
        if self.audioPlayer.duration > 0 {
            self.audioPlayer.seek(toTime: toTime)
        }
        
        savePlaybackPosition()
    }
    
    func updateMPNowPlayingInfoCenter() {
        guard let item =  self.nowPlayingItem else {
            return
        }
        
        let currentPlaybackTime = NSNumber(value: self.progress)
        let currentPlayerRate = NSNumber(value: self.playerSpeedRate.speedValue)
        
        if let podcastImageUrlString = item.podcastImageUrl, let podcastImageUrl = URL(string: podcastImageUrlString) {
            if let data = try? Data(contentsOf: podcastImageUrl), let image = UIImage(data: data) {
                let artwork = MPMediaItemArtwork.init(boundsSize: image.size, requestHandler: { size -> UIImage in
                    return image
                })
                
                MPNowPlayingInfoCenter.default().nowPlayingInfo = [MPMediaItemPropertyArtist: item.podcastTitle ?? "", MPMediaItemPropertyTitle: item.episodeTitle ?? "", MPMediaItemPropertyArtwork: artwork, MPMediaItemPropertyPlaybackDuration: self.duration ?? "", MPNowPlayingInfoPropertyElapsedPlaybackTime: currentPlaybackTime, MPNowPlayingInfoPropertyPlaybackRate: currentPlayerRate]
                
            }
        }
    }
    
    func play() {
        self.audioPlayer.rate = self.playerSpeedRate.speedValue
        savePlaybackPosition()
        self.audioPlayer.resume()
        self.shouldAutoplayOnce = false
    }
    
    func pause() {
        savePlaybackPosition()
        self.audioPlayer.rate = 0.0
        self.audioPlayer.pause()
    }
    
    @objc func playerDidFinishPlaying() {
        
        if let nowPlayingItem = playerHistoryManager.historyItems.first {
            
            clearPlaybackPosition()
            
            if let episodeMediaUrl = nowPlayingItem.episodeMediaUrl, let episode = Episode.episodeForMediaUrl(mediaUrlString: episodeMediaUrl, managedObjectContext: moc) {
                PVDeleter.deleteEpisode(mediaUrl: episode.mediaUrl, fileOnly: true, shouldCallNotificationMethod: true)
            }
            
            nowPlayingItem.hasReachedEnd = true
            playerHistoryManager.addOrUpdateItem(item: nowPlayingItem)
            
            if UserDefaults.standard.bool(forKey: kShouldPlayContinuously) {
                var podcast:Podcast?
                
                if let podcastId = nowPlayingItem.podcastId  {
                    podcast = Podcast.podcastForId(id: podcastId, managedObjectContext: moc)
                } else if let podcastFeedUrl = nowPlayingItem.podcastFeedUrl {
                    podcast = Podcast.podcastForFeedUrl(feedUrlString: podcastFeedUrl, managedObjectContext: moc)
                }
                
                if let episodeMediaUrl = nowPlayingItem.episodeMediaUrl, let nextDownloadedEpisode = podcast?.retrieveNextDownloadedEpisode(currentEpisodeMediaUrl: episodeMediaUrl) {
                    self.shouldAutoplayOnce = true
                    let playerHistoryItem = self.playerHistoryManager.convertEpisodeToPlayerHistoryItem(episode: nextDownloadedEpisode)
                    self.loadPlayerHistoryItem(item: playerHistoryItem)
                    
                    // Return out of function so the playerHasFinished notification is not posted, so the MediaPlayerVC doesn't pop back a page after playDidFinish
                    return
                }
            }
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .playerHasFinished, object: nil, userInfo: nil)
            }
            
        }
    }
    
    // If you seek before the startTime of a clip, this will return true. Returns false if a clip has an endTime, and the progress moves later than the endTime.
    func isInClipTimeRange() -> Bool {
        
        guard let item = self.nowPlayingItem, item.isClip(), let _ = item.startTime else {
            return false
        }
        
        guard let endTime = item.endTime else {
            return true
        }
        
        if self.progress > Double(endTime) {
            return false
        } else {
            return true
        }
        
    }
    
    func setPlayingInfo() {
        guard let item =  self.nowPlayingItem else {
            return
        }
        
        let rate = self.audioPlayer.rate
        let currentPlaybackTime = NSNumber(value: self.progress)
        
        let podcastImage = Podcast.retrievePodcastImage(podcastImageURLString: item.podcastImageUrl, feedURLString: item.podcastFeedUrl, completion: { image in
            MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPMediaItemPropertyArtwork] = MPMediaItemArtwork.init(boundsSize: image.size, requestHandler: { size -> UIImage in
                return image
            })
        })
        
        let artwork = MPMediaItemArtwork.init(boundsSize: podcastImage.size, requestHandler: { size -> UIImage in
            return podcastImage
        })
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyArtist: item.podcastTitle ?? "",
            MPMediaItemPropertyTitle: item.episodeTitle ?? "",
            MPMediaItemPropertyArtwork: artwork,
            MPMediaItemPropertyPlaybackDuration: self.duration ?? "",
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentPlaybackTime,
            MPNowPlayingInfoPropertyPlaybackRate: rate
        ]
    }
    
    // This is only used when an episode/clip should appear loaded in the player, but it should not start streaming or playing. Since StreamingKit automatically plays a file as soon as you load it, this retrieveRemoteFileDuration method uses AVURLAsset to determine the duration of a remote media file if no stream is loaded.
    func updateDuration(episodeMediaUrl: String?) {
        if let episodeMediaUrl = episodeMediaUrl, let url = URL(string: episodeMediaUrl) {
            let asset = AVURLAsset(url: url, options: nil)
            self.duration = CMTimeGetSeconds(asset.duration)
        } else {
            self.duration = self.audioPlayer.duration
        }
    }
    
    func loadPlayerHistoryItem(item: PlayerHistoryItem, startFromLastPlaybackPosition: Bool = false) {
        
        self.audioPlayer.dispose()
        self.audioPlayer = STKAudioPlayer()
        self.audioPlayer.delegate = self
        
        self.nowPlayingItem = item
        self.nowPlayingItem?.hasReachedEnd = false
        self.shouldHideClipDataNextPlay = false
        
        self.playerHistoryManager.addOrUpdateItem(item: nowPlayingItem)
        
        self.isItemLoaded = false
        self.delegate?.playerHistoryItemLoadingBegan()
        
        // Pausing before attempting to play seems to help with playback issues.
        // If the audioPlayer was last in the errored state, attempting to pause will cause the app to crash.
        if self.hasErrored {
            self.hasErrored = false
        }
        
        if let lastPlaybackPosition = item.lastPlaybackPosition, !self.shouldSetupClip {
            self.shouldStartFromTime = lastPlaybackPosition
        }
        
        // NOTE: calling audioPlayer.play will immediately start playback, so do not call it unless an autoplay flag is true
        if !shouldAutoplayOnce && !shouldAutoplayAlways {
            updateDuration(episodeMediaUrl: item.episodeMediaUrl)
            
            if item.isClip(), let startTime = item.startTime {
                seek(toTime: Double(startTime))
            }
            
            return
        }
                
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
                        self.audioPlayer.play(destinationUrl)
                        
                    } else {
                        self.audioPlayer.play(episodeMediaUrl)
                    }
                }
            }

            // Else remotely stream the whole episode.
            else {
                self.audioPlayer.play(episodeMediaUrl)
            }
            
            if (!startFromLastPlaybackPosition) {
                self.shouldSetupClip = item.isClip()
            } else {
                self.shouldSetupClip = false
            }
            

        }
        
        // NOTE: this must be called after duration is set, or the duration may not be available for the MPNowPlayingInfoCenter
        setPlayingInfo()
        
    }
    
    @objc func playInterrupted(notification: NSNotification) {
        if notification.name == NSNotification.Name.AVAudioSessionInterruption, let userInfo = notification.userInfo {
            var intValue: UInt = 0
            (userInfo[AVAudioSessionInterruptionTypeKey] as! NSValue).getValue(&intValue)
            
            switch AVAudioSessionInterruptionType(rawValue: intValue) {
                case .some(.began):
                    savePlaybackPosition()
                case .some(.ended):
                    var intOptionValue: UInt = 0
                    (userInfo[AVAudioSessionInterruptionOptionKey] as! NSValue).getValue(&intOptionValue)
                    if intOptionValue == AVAudioSessionInterruptionFlags_ShouldResume && self.audioPlayer.state == .playing, let item = self.nowPlayingItem {
                        // Resuming from background might not work in StreamingKit, so I am loading the playerHistoryItem over again
                        // Using startFromLastPlaybackPosition so if a clip is now playing, then it will resume from the last playback position instead of the clip start time
                        self.loadPlayerHistoryItem(item: item, startFromLastPlaybackPosition: true)
                    }
                default:
                    break
            }
        }
    }
    
}

extension PVMediaPlayer:STKAudioPlayerDelegate {
    
    func audioPlayer(_ audioPlayer: STKAudioPlayer, stateChanged state: STKAudioPlayerState, previousState: STKAudioPlayerState) {
        
        if let item = self.nowPlayingItem {
            if state == .buffering {
                self.delegate?.playerHistoryItemBuffering()
                return
            }
            
            if state == .error {
                self.hasErrored = true
                self.delegate?.playerHistoryItemErrored()
                return
            }
            
            if state == .paused {
                self.delegate?.playerHistoryItemPaused()
                return
            }
            
            if state == .playing {
                
                if self.audioPlayer.duration > 0 {
                    updateDuration(episodeMediaUrl: nil)
                    
                    if self.shouldSetupClip == true {
                        if let startTime = item.startTime {
                            self.seek(toTime: Double(startTime))
                        }
                        
                        if let endTime = item.endTime {
                            self.shouldStopAtEndTime = endTime
                        }
                        
                        self.shouldSetupClip = false
                        
                        if self.shouldStartFromTime > 0 {
                            self.audioPlayer.seek(toTime: Double(self.shouldStartFromTime))
                            self.shouldStartFromTime = 0
                            self.isItemLoaded = true
                        }
                        
                    } else if self.shouldStartFromTime > 0 {
                        self.audioPlayer.seek(toTime: Double(self.shouldStartFromTime))
                        self.shouldStartFromTime = 0
                        self.isItemLoaded = true
                    }
                    
                }
                
                self.delegate?.playerHistoryItemLoaded()
                
            }
            
            if state == .playing && !self.shouldSetupClip && self.shouldStartFromTime == 0 {
                self.isItemLoaded = true
                self.delegate?.playerHistoryItemLoaded()
            }
            
        }
    }
    
    func audioPlayer(_ audioPlayer: STKAudioPlayer, didCancelQueuedItems queuedItems: [Any]) {
        
    }
    
    func audioPlayer(_ audioPlayer: STKAudioPlayer, didStartPlayingQueueItemId queueItemId: NSObject) {
        
    }
    
    func audioPlayer(_ audioPlayer: STKAudioPlayer, didFinishBufferingSourceWithQueueItemId queueItemId: NSObject) {
        
    }
    
    func audioPlayer(_ audioPlayer: STKAudioPlayer, didFinishPlayingQueueItemId queueItemId: NSObject, with stopReason: STKAudioPlayerStopReason, andProgress progress: Double, andDuration duration: Double) {
        playerDidFinishPlaying()
    }
    
    func audioPlayer(_ audioPlayer: STKAudioPlayer, unexpectedError errorCode: STKAudioPlayerErrorCode) {
        print(errorCode)
    }
    
}
