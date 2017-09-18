//
//  MediaPlayerViewController.swift
//  Podverse
//
//  Created by Mitchell Downey on 5/17/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

import AVFoundation
import CoreData
import StreamingKit
import UIKit

class MediaPlayerViewController: PVViewController {
    
    let audioPlayer = PVMediaPlayer.shared.audioPlayer
    var playerSpeedRate:PlayingSpeed = .regular
    let reachability = PVReachability.shared
    var timer: Timer?
    
    weak var currentChildViewController: UIViewController?
    private let aboutClipsStoryboardId = "AboutPlayingItemVC"
    private let clipsListStoryBoardId = "ClipsListVC"
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var clipsContainerView: UIView!
    @IBOutlet weak var currentTime: UILabel!
    @IBOutlet weak var device: UIButton!
    @IBOutlet weak var duration: UILabel!
    @IBOutlet weak var episodeTitle: UILabel!
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var play: UIButton!
    @IBOutlet weak var podcastTitle: UILabel!
    @IBOutlet weak var progress: UISlider!
    @IBOutlet weak var speed: UIButton!
    @IBOutlet weak var startTimeFlagView: UIView!
    @IBOutlet weak var endTimeFlagView: UIView!
    @IBOutlet weak var startTimeLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var endTimeLeadingConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        setupContainerView()
        
        pvMediaPlayer.delegate = self
        
        let share = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.action, target: self, action: #selector(showShareMenu))
        let makeClip = UIBarButtonItem(title: "Make Clip", style: .plain, target: self, action: #selector(showMakeClip))
        let addToPlaylist = UIBarButtonItem(title: "Add to Playlist", style: .plain, target: self, action: #selector(showAddToPlaylist))
        navigationItem.rightBarButtonItems = [share, makeClip, addToPlaylist]

        self.progress.setThumbImage(#imageLiteral(resourceName: "SliderCurrentPosition"), for: .normal)
        
        populatePlayerInfo()
        
        self.tabBarController?.hidePlayerView()
        
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        
        addObservers()
        
        self.activityIndicator.startAnimating()
        
        setupTimer()
        setupClipFlags()
    }
    
    deinit {
        removeObservers()
        removeTimer()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        togglePlayIcon()
        updateTime()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    @IBAction func pageControlAction(_ sender: Any) {
        if let sender = sender as? UIPageControl {
            if sender.currentPage == 1 {
                showClipsContainerView()
            } else {
                showAboutView()
            }
        }
    }
    
    @IBAction func sliderAction(_ sender: Any, forEvent event: UIEvent) {
        if let sender = sender as? UISlider, let touchEvent = event.allTouches?.first {
            switch touchEvent.phase {
            case .began:
                removeTimer()
            case .ended:
                if let duration = pvMediaPlayer.duration {
                    let newTime = Double(sender.value) * duration
                    self.pvMediaPlayer.seek(toTime: newTime)
                    updateTime()
                }
                setupTimer()
            default:
                break
            }
        }
    }
    
    
    @IBAction func play(_ sender: Any) {
        self.pvMediaPlayer.playOrPause()
    }

    @IBAction func timeJumpBackward(_ sender: Any) {
        let newTime = self.audioPlayer.progress - 15
        
        if newTime >= 14 {
            self.pvMediaPlayer.seek(toTime: newTime)
        } else {
            self.pvMediaPlayer.seek(toTime: 0)
        }
        
        updateTime()
    }
    
    @IBAction func timeJumpForward(_ sender: Any) {
        let newTime = self.audioPlayer.progress + 15
        self.pvMediaPlayer.seek(toTime: newTime)
        updateTime()
    }
    
    @IBAction func changeSpeed(_ sender: Any) {
        switch playerSpeedRate {
        case .regular:
            playerSpeedRate = .timeAndQuarter
            break
        case .timeAndQuarter:
            playerSpeedRate = .timeAndHalf
            break
        case .timeAndHalf:
            playerSpeedRate = .double
            break
        case .double:
            playerSpeedRate = .doubleAndHalf
            break
        case .doubleAndHalf:
            playerSpeedRate = .quarter
            break
        case .quarter:
            playerSpeedRate = .half
            break
        case .half:
            playerSpeedRate = .threeQuarts
            break
        case .threeQuarts:
            playerSpeedRate = .regular
            break
        }
        
        audioPlayer.rate = playerSpeedRate.speedValue

        updateSpeedLabel()
    }
    
    func pause() {
        pvMediaPlayer.pause()
    }
    
    fileprivate func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(pause), name: .playerHasFinished, object: nil)
        self.addObserver(self, forKeyPath: #keyPath(audioPlayer.state), options: [.new, .old], context: nil)
    }
    
    fileprivate func removeObservers() {
        NotificationCenter.default.removeObserver(self, name: .playerHasFinished, object: nil)
        self.removeObserver(self, forKeyPath: #keyPath(audioPlayer.state))
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let keyPath = keyPath {
            if keyPath == #keyPath(audioPlayer.state) {
                self.togglePlayIcon()
                self.updateTime()
            }
        }
    }
        
    fileprivate func setupContainerView() {
        if let currentVC = self.storyboard?.instantiateViewController(withIdentifier: self.aboutClipsStoryboardId) {
            self.currentChildViewController = currentVC
            self.currentChildViewController?.view.translatesAutoresizingMaskIntoConstraints = false
            self.addChildViewController(currentVC)
            self.addSubview(subView: currentVC.view, toView: self.clipsContainerView)
        }
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(MediaPlayerViewController.showClipsContainerView))
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(MediaPlayerViewController.showAboutView))
        swipeLeft.direction = .left
        swipeRight.direction = .right
        self.clipsContainerView.addGestureRecognizer(swipeLeft)
        self.clipsContainerView.addGestureRecognizer(swipeRight)
        
        self.clipsContainerView.layer.borderColor = UIColor.lightGray.cgColor
        self.clipsContainerView.layer.borderWidth = 1.0
        
        self.pageControl.currentPage = 0
    }
    
    private func togglePlayIcon() {
        DispatchQueue.main.async {
            if self.audioPlayer.state == STKAudioPlayerState.buffering {
                self.activityIndicator.isHidden = false
                self.play.isHidden = true
            } else if self.audioPlayer.state == STKAudioPlayerState.playing {
                self.activityIndicator.isHidden = true
                self.play.setImage(UIImage(named:"Pause"), for: .normal)
                self.play.isHidden = false
            } else {
                self.activityIndicator.isHidden = true
                self.play.setImage(UIImage(named:"Play"), for: .normal)
                self.play.isHidden = false
            }
        }
    }
    
    func populatePlayerInfo() {
        if let item = self.pvMediaPlayer.nowPlayingItem {
            podcastTitle.text = item.podcastTitle
            episodeTitle.text = item.episodeTitle
            
            self.image.sd_setImage(with: URL(string: item.podcastImageUrl ?? ""), placeholderImage: #imageLiteral(resourceName: "PodverseIcon"))
            if let dur = self.pvMediaPlayer.duration {
                duration.text = Int64(dur).toMediaPlayerString()
            }
        }
    }
    
    @objc private func updateTime () {
        DispatchQueue.main.async {
            if self.audioPlayer.state == STKAudioPlayerState.buffering {
                self.currentTime.text = "--:--"
                self.duration.text = "--:--"
            } else {
                
                var playbackPosition = 0.0
                if self.pvMediaPlayer.progress > 0 {
                    playbackPosition = self.pvMediaPlayer.progress
                } else if let dur = self.pvMediaPlayer.duration {
                    playbackPosition = Double(self.progress.value) * dur
                }
                
                self.currentTime.text = Int64(playbackPosition).toMediaPlayerString()
                
                if let dur = self.pvMediaPlayer.duration {
                    self.duration.text = Int64(dur).toMediaPlayerString()
                    self.progress.value = Float(playbackPosition / dur)
                }
            }
        }
    }
    
    private func setupTimer () {
        timer = Timer.scheduledTimer(timeInterval: 0.25, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
    }
    
    private func removeTimer () {
        if let timer = timer {
            timer.invalidate()
        }
    }
    
    func updateSpeedLabel() {
        speed.setTitle(playerSpeedRate.speedText, for: .normal)
    }
    
    func showAddToPlaylist() {
        
        if self.reachability.hasInternetConnection() == false {
            self.showInternetNeededAlertWithDesciription(message: "You must be connected to the internet to add to playlists.")
            return
        }
        
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"Player", style:.plain, target:nil, action:nil)
        
        let addToPlaylistActions = UIAlertController(title: "Add to Playlist", message: "", preferredStyle: UIAlertControllerStyle.actionSheet)
        
        addToPlaylistActions.addAction(UIAlertAction(title: "Full Episode", style: .default, handler: { action in
            self.performSegue(withIdentifier: "Show Add to Playlist", sender: "Full Episode")
        }))
        
        addToPlaylistActions.addAction(UIAlertAction(title: "Current Clip", style: .default, handler: { action in
            self.performSegue(withIdentifier: "Show Add to Playlist", sender: "Current Clip")
        }))
        
        addToPlaylistActions.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(addToPlaylistActions, animated: true, completion: nil)
        
    }
    
    func showMakeClip() {
        
        if self.reachability.hasInternetConnection() == false {
            self.showInternetNeededAlertWithDesciription(message: "You must be connected to the internet to make clips.")
            return
        }
        
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"Player", style:.plain, target:nil, action:nil)
        self.performSegue(withIdentifier: "Show Make Clip Time", sender: self)
        
    }
    
    func showShareMenu() {
        
        let shareActions = UIAlertController(title: "Share", message: "What do you want to share?", preferredStyle: .actionSheet)
        
        shareActions.addAction(UIAlertAction(title: "Episode Link", style: .default, handler: { action in
            if let item = self.playerHistoryManager.historyItems.first, let episodeMediaUrl = item.episodeMediaUrl {
                let episodeUrlItem = [BASE_URL + "episodes/alias?mediaURL=" + episodeMediaUrl]
                let activityViewController = UIActivityViewController(activityItems: episodeUrlItem, applicationActivities: nil)
                activityViewController.popoverPresentationController?.sourceView = self.view
                self.present(activityViewController, animated: true, completion: nil)
            }
        }))
        
        shareActions.addAction(UIAlertAction(title: "Clip Link", style: .default, handler: { action in
            if let item = self.playerHistoryManager.historyItems.first, let mediaRefId = item.mediaRefId {
                let mediaRefUrlItem = [BASE_URL + "clips/" + mediaRefId]
                let activityViewController = UIActivityViewController(activityItems: mediaRefUrlItem, applicationActivities: nil)
                activityViewController.popoverPresentationController?.sourceView = self.view
                self.present(activityViewController, animated: true, completion: nil)
            }
        }))
        
        if let item = self.playerHistoryManager.historyItems.first {
            if item.mediaRefId == nil {
                shareActions.actions[1].isEnabled = false
            }
        }
        
        shareActions.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(shareActions, animated: true, completion: nil)
        
    }
    
    func showAboutView() {
        if let newViewController = self.storyboard?.instantiateViewController(withIdentifier: self.aboutClipsStoryboardId), self.currentChildViewController is ClipsListContainerViewController {
            newViewController.view.translatesAutoresizingMaskIntoConstraints = false
            self.cycleFromViewController(oldViewController: self.currentChildViewController!, toViewController: newViewController)
            self.currentChildViewController = newViewController
            pageControl.currentPage = 0
        }
    }
    
    func showClipsContainerView() {
        if let newViewController = self.storyboard?.instantiateViewController(withIdentifier: self.clipsListStoryBoardId) as? ClipsListContainerViewController, self.currentChildViewController is AboutPlayingItemViewController {
            newViewController.view.translatesAutoresizingMaskIntoConstraints = false
            self.cycleFromViewController(oldViewController: self.currentChildViewController!, toViewController: newViewController)
            self.currentChildViewController = newViewController
            newViewController.delegate = self
            pageControl.currentPage = 1
        }    
    }
    
    private func addSubview(subView:UIView, toView parentView:UIView) {
        parentView.addSubview(subView)
        
        var viewBindingsDict = [String: AnyObject]()
        viewBindingsDict["subView"] = subView
        parentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[subView]|",
                                                                                 options: [], metrics: nil, views: viewBindingsDict))
        parentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[subView]|",
                                                                                 options: [], metrics: nil, views: viewBindingsDict))
    }
    
    private func cycleFromViewController(oldViewController: UIViewController, toViewController newViewController: UIViewController) {
        oldViewController.willMove(toParentViewController: nil)
        self.addChildViewController(newViewController)
        self.addSubview(subView: newViewController.view, toView:self.clipsContainerView)
        
        let initialX = newViewController is ClipsListContainerViewController ? self.clipsContainerView.frame.maxX : -self.clipsContainerView.frame.maxX
        newViewController.view.frame = CGRect(x: initialX, 
                                              y: 0.0, 
                                              width: newViewController.view.frame.width, 
                                              height: newViewController.view.frame.height)
        
        UIView.animate(withDuration: 0.5, animations: {
            if newViewController is ClipsListContainerViewController {
                oldViewController.view.frame = CGRect(x: -oldViewController.view.frame.width, 
                                                      y: 0.0, 
                                                      width: oldViewController.view.frame.width, 
                                                      height: oldViewController.view.frame.height)
            }
            else {
                oldViewController.view.frame = CGRect(x: oldViewController.view.frame.width, 
                                                      y: 0.0, 
                                                      width: oldViewController.view.frame.width, 
                                                      height: oldViewController.view.frame.height)
            }
            newViewController.view.frame = CGRect(x: 0.0, 
                                                  y: 0.0, 
                                                  width: newViewController.view.frame.width, 
                                                  height: newViewController.view.frame.height)
        },
           completion: { finished in
            oldViewController.view.removeFromSuperview()
            oldViewController.removeFromParentViewController()
            newViewController.didMove(toParentViewController: self)
        })
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "Show Add to Playlist" {
            
            if let sender = sender as? String, let nowPlayingItem = playerHistoryManager.historyItems.first, let addToPlaylistViewController = segue.destination as? AddToPlaylistViewController {
                if sender == "Full Episode" {
                    addToPlaylistViewController.shouldSaveFullEpisode = true
                } else {
                    addToPlaylistViewController.shouldSaveFullEpisode = false
                }
                
                addToPlaylistViewController.playerHistoryItem = nowPlayingItem
            }
            
        } else if segue.identifier == "Show Make Clip Time" {
            
            if let nowPlayingItem = playerHistoryManager.historyItems.first, let makeClipTimeViewController = segue.destination as? MakeClipTimeViewController {
                makeClipTimeViewController.playerHistoryItem = nowPlayingItem
                makeClipTimeViewController.startTime = Int(self.audioPlayer.progress)
            }
            
        }
        
    }
    
    fileprivate func setupClipFlags() {
        self.startTimeLeadingConstraint.constant = 0
        self.endTimeLeadingConstraint.constant = 0
        let sliderThumbWidthAdjustment:CGFloat = 2.0
        
        if let 
            nowPlayingItem = self.pvMediaPlayer.nowPlayingItem, 
            let startTime = nowPlayingItem.startTime, 
            let endTime = nowPlayingItem.endTime, 
            let duration = self.pvMediaPlayer.duration, 
            nowPlayingItem.isClip() {
            
            self.startTimeFlagView.isHidden = false
            self.endTimeFlagView.isHidden = self.pvMediaPlayer.nowPlayingItem?.endTime == nil
            
            self.startTimeLeadingConstraint.constant = (CGFloat(Double(startTime) / duration) * progress.frame.width) - sliderThumbWidthAdjustment
            self.endTimeLeadingConstraint.constant = (CGFloat(Double(endTime) / duration) * progress.frame.width) - sliderThumbWidthAdjustment
        }
        else {
            self.startTimeFlagView.isHidden = true
            self.endTimeFlagView.isHidden = true
        }
    }
    
}

extension MediaPlayerViewController:PVMediaPlayerUIDelegate {
    
    func mediaPlayerButtonStateChanged(showPlayerButton: Bool) {}
    
    func playerHistoryItemLoadingBegan() {
        DispatchQueue.main.async {
            self.populatePlayerInfo()
        }
    }
    
    func playerHistoryItemLoaded() {
        DispatchQueue.main.async {
            self.setupClipFlags()
        }
    }
    
}

extension MediaPlayerViewController:ClipsListDelegate {
    func didSelectClip(clip: MediaRef) {
        DispatchQueue.main.async {
            let playerHistoryItem = self.playerHistoryManager.convertMediaRefToPlayerHistoryItem(mediaRef: clip)
            self.pvMediaPlayer.loadPlayerHistoryItem(item: playerHistoryItem)
        }
    }
}
