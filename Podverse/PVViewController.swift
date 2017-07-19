//
//  PVViewController.swift
//  Podverse
//
//  Created by Mitchell Downey on 5/8/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

import UIKit

class PVViewController: UIViewController {
    
    let playerHistoryManager = PlayerHistory.manager
    let pvMediaPlayer = PVMediaPlayer.shared
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.plain, target:nil, action:nil)
        setupNotificationListeners()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadNowPlayingBarData()
    }
    
    deinit {
        removeObservers()
    }
    
    fileprivate func setupNotificationListeners() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.episodeDeleted(_:)), name: .episodeDeleted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.podcastDeleted(_:)), name: .podcastDeleted, object: nil)
    }
    
    fileprivate func removeObservers() {
        NotificationCenter.default.removeObserver(self, name: .episodeDeleted, object: nil)
        NotificationCenter.default.removeObserver(self, name: .podcastDeleted, object: nil)
    }
    
    
    func loadNowPlayingBarData() {
        guard let currentItem = playerHistoryManager.historyItems.first, let tabbarVC = self.tabBarController, PVMediaPlayer.shared.currentlyPlayingItem != nil && currentItem.wasDeleted != true else {
            self.tabBarController?.hidePlayerView()
            return
        }
        
        tabbarVC.playerView.podcastTitleLabel.text = currentItem.podcastTitle
        tabbarVC.playerView.episodeTitle.text = currentItem.episodeTitle
        tabbarVC.playerView.podcastImageView.image = Podcast.retrievePodcastImage(podcastImageURLString: currentItem.podcastImageUrl, 
                                                                       feedURLString: currentItem.podcastFeedUrl) { (podcastImage) -> Void in
                                              tabbarVC.playerView.podcastImageView.image = podcastImage
                                          }
        tabbarVC.playerView.isPlaying = self.pvMediaPlayer.mediaPlayerIsPlaying
        tabbarVC.showPlayerView()
    }
    
    func goToNowPlaying() {
        self.tabBarController?.goToMediaPlayer()
    }
}

extension PVViewController {
    func episodeDeleted(_ notification:Notification) {
        if let mediaUrl = notification.userInfo?["mediaUrl"] as? String {
            if playerHistoryManager.checkIfEpisodeWasLastPlayed(mediaUrl: mediaUrl) == true {
                self.tabBarController?.hidePlayerView()
            }
        }
    }
    
    func podcastDeleted(_ notification:Notification) {
        if let feedUrl = notification.userInfo?["feedUrl"] as? String {
            if playerHistoryManager.checkIfPodcastWasLastPlayed(feedUrl: feedUrl) == true {
                self.tabBarController?.hidePlayerView()
            }
        }
    }
}
