//
//  PVViewController.swift
//  Podverse
//
//  Created by Mitchell Downey on 5/8/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

import UIKit

protocol TableViewHeightProtocol:class {
    func adjustTableView()
}

class PVViewController: UIViewController {
    
    let playerHistoryManager = PlayerHistory.manager
    let pvMediaPlayer = PVMediaPlayer.shared
    static weak var delegate:TableViewHeightProtocol?
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        PVDeleter.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.plain, target:nil, action:nil)
        PVViewController.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadNowPlayingBarData()
    }
    
    func loadNowPlayingBarData() {
        guard let currentItem = playerHistoryManager.historyItems.first, let tabbarVC = self.tabBarController, PVMediaPlayer.shared.currentlyPlayingItem != nil && currentItem.didFinishPlaying != true else {
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

extension PVViewController:PVDeleterDelegate {
    func podcastDeleted(feedUrl: String?) {
        if let feedUrl = feedUrl {
            if playerHistoryManager.checkIfPodcastWasLastPlayed(feedUrl: feedUrl) == true {
                self.tabBarController?.hidePlayerView()
            }
        }
    }
    
    func episodeDeleted(mediaUrl: String?) {
        if let mediaUrl = mediaUrl {
            if playerHistoryManager.checkIfEpisodeWasLastPlayed(mediaUrl: mediaUrl) == true {
                self.tabBarController?.hidePlayerView()
            }
        }
    }
}

extension PVViewController:TableViewHeightProtocol {
    func adjustTableView() {
        if let index = self.view.constraints.index(where: {$0.secondItem is UITableView && $0.secondAttribute == NSLayoutAttribute.bottom }) {
            self.view.constraints[index].constant = self.tabBarController!.playerView.isHidden ? 0.0 : (self.tabBarController?.playerView.frame.height ?? 0.0)
        }
    }
}
