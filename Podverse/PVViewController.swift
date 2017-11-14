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
        PVViewController.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        pvMediaPlayer.delegate = self.tabBarController?.playerView
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

    func updateNowPlayingBarData(completion: @escaping (_ shouldShow: Bool) -> Void) {
        DispatchQueue.main.async {
            guard let currentItem = self.playerHistoryManager.historyItems.first, let tabbarVC = self.tabBarController, PVMediaPlayer.shared.nowPlayingItem != nil && currentItem.hasReachedEnd != true else {
                completion(false)
                return
            }
            
            tabbarVC.playerView.podcastTitleLabel.text = currentItem.podcastTitle
            tabbarVC.playerView.episodeTitle.text = currentItem.episodeTitle
            
            tabbarVC.playerView.podcastImageView.image = Podcast.retrievePodcastImage(podcastImageURLString: currentItem.podcastImageUrl, feedURLString: currentItem.podcastFeedUrl, managedObjectID: nil, completion: { image in
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
    func episodeDeleted(_ notification:Notification) {
        if let mediaUrl = notification.userInfo?["mediaUrl"] as? String {
            if playerHistoryManager.checkIfEpisodeWasLastPlayed(mediaUrl: mediaUrl) == true {
                DispatchQueue.main.async {
                    self.tabBarController?.hidePlayerView()
                }
            }
        }
    }
    
    func podcastDeleted(_ notification:Notification) {
        if let feedUrl = notification.userInfo?["feedUrl"] as? String {
            if playerHistoryManager.checkIfPodcastWasLastPlayed(feedUrl: feedUrl) == true {
                DispatchQueue.main.async {
                    self.tabBarController?.hidePlayerView()
                }
            }
        }
    }
}

extension PVViewController:TableViewHeightProtocol {
    func adjustTableView() {
        if let index = self.view.constraints.index(where: {$0.secondItem is UITableView && $0.secondAttribute == NSLayoutAttribute.bottom }),
           let tabbarVC = self.tabBarController {
            self.view.constraints[index].constant = tabbarVC.playerView.isHidden ? 0.0 : tabbarVC.playerView.frame.height - 0.5
        }
    }
}
