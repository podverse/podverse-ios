//
//  PVViewController.swift
//  Podverse
//
//  Created by Mitchell Downey on 5/8/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

import UIKit
import StreamingKit
import SDWebImage

protocol TableViewHeightProtocol:class {
    func adjustTableView()
}

class PVViewController: UIViewController {
    
    let playerHistoryManager = PlayerHistory.manager
    let pvMediaPlayer = PVMediaPlayer.shared
    static weak var delegate:TableViewHeightProtocol?
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.plain, target:nil, action:nil)
        addObservers()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        pvMediaPlayer.delegate = self.tabBarController?.playerView
        PVViewController.delegate = self
        toggleNowPlayingBar()
    }
    
    deinit {
        removeObservers()
    }
    
    fileprivate func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.episodeDeleted(_:)), name: .episodeDeleted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.podcastDeleted(_:)), name: .podcastDeleted, object: nil)
    }
    
    fileprivate func removeObservers() {
        NotificationCenter.default.removeObserver(self, name: .episodeDeleted, object: nil)
        NotificationCenter.default.removeObserver(self, name: .podcastDeleted, object: nil)
    }
    
    func toggleNowPlayingBar() {
        self.updateNowPlayingBarData() { shouldShow in
            if shouldShow {
                self.tabBarController?.showPlayerView()
            } else {
                self.tabBarController?.hidePlayerView()
            }
        }
    }
    
    func hideNowPlayingBar() {
        self.tabBarController?.hidePlayerView()
    }

    func updateNowPlayingBarData(completion: @escaping (_ shouldShow: Bool) -> Void) {
        DispatchQueue.main.async {
            guard let currentItem = self.playerHistoryManager.historyItems.first, let tabbarVC = self.tabBarController, PVMediaPlayer.shared.nowPlayingItem != nil && currentItem.hasReachedEnd != true else {
                completion(false)
                return
            }
            
            tabbarVC.playerView.podcastTitleLabel.text = currentItem.podcastTitle?.stringByDecodingHTMLEntities()
            tabbarVC.playerView.episodeTitle.text = currentItem.episodeTitle?.stringByDecodingHTMLEntities()
            
            tabbarVC.playerView.podcastImageView.image = Podcast.retrievePodcastImage(podcastImageURLString: currentItem.podcastImageUrl, feedURLString: currentItem.podcastFeedUrl, completion: { image in
                tabbarVC.playerView.podcastImageView.image = image
            })
            
            tabbarVC.playerView.togglePlayIcon()
            
            completion(true)
        }
    }
    
    func goToNowPlaying() {
        self.tabBarController?.goToNowPlaying()
    }
    
}

extension PVViewController {
    @objc func episodeDeleted(_ notification:Notification) {
        if let mediaUrl = notification.userInfo?["mediaUrl"] as? String {
            if playerHistoryManager.checkIfEpisodeWasLastPlayed(mediaUrl: mediaUrl) == true {
                DispatchQueue.main.async {
                    self.tabBarController?.hidePlayerView()
                }
            }
        }
    }
    
    @objc func podcastDeleted(_ notification:Notification) {
        
        if let podcastId = notification.userInfo?["podcastId"] as? String, playerHistoryManager.checkIfPodcastWasLastPlayed(podcastId: podcastId, feedUrl: nil) == true {
            DispatchQueue.main.async {
                self.tabBarController?.hidePlayerView()
            }
        }

        
        if let feedUrl = notification.userInfo?["feedUrl"] as? String, playerHistoryManager.checkIfPodcastWasLastPlayed(podcastId: nil, feedUrl: feedUrl) == true {
            DispatchQueue.main.async {
                self.tabBarController?.hidePlayerView()
            }
        }
    }
}

extension PVViewController:TableViewHeightProtocol {
    func adjustTableView() {
        if let index = self.view.constraints.index(where: {$0.secondItem is UITableView && $0.secondAttribute == NSLayoutAttribute.bottom }),
           let tabbarVC = self.tabBarController {
            self.view.constraints[index].constant = tabbarVC.playerView.isHidden ? 0.0 : tabbarVC.playerView.frame.height - 0.5
        } else if let index = self.view.constraints.index(where: {$0.secondItem is UITableView && $0.secondAttribute == NSLayoutAttribute.bottom }) {
            self.view.constraints[index].constant = self.tabBarController?.tabBar.frame.height ?? 0.0
        }
    }
}
