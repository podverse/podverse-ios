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
        toggleNowPlayingBar()
    }
    
    deinit {
        removeObservers()
    }
    
    fileprivate func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.episodeDeleted(_:)), name: .episodeDeleted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.podcastDeleted(_:)), name: .podcastDeleted, object: nil)
        self.addObserver(self, forKeyPath: #keyPath(pvMediaPlayer.audioPlayer.state), options: [.new, .old], context: nil)
    }
    
    fileprivate func removeObservers() {
        NotificationCenter.default.removeObserver(self, name: .episodeDeleted, object: nil)
        NotificationCenter.default.removeObserver(self, name: .podcastDeleted, object: nil)
        self.removeObserver(self, forKeyPath: #keyPath(pvMediaPlayer.audioPlayer.state))
    }
    
    func toggleNowPlayingBar() {
        self.updateNowPlayingBarData() { shouldShow in
            let tabbarVC = self.tabBarController
            
            if shouldShow {
                tabbarVC?.showPlayerView()
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
            tabbarVC.playerView.podcastImageView.sd_setImage(with: URL(string: currentItem.podcastImageUrl ?? ""), placeholderImage: #imageLiteral(resourceName: "PodverseIcon"))
            tabbarVC.playerView.isPlaying = (self.pvMediaPlayer.audioPlayer.state == STKAudioPlayerState.playing)
            
            completion(true)
        }
    }
    
    func goToNowPlaying() {
        self.tabBarController?.goToNowPlaying()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let keyPath = keyPath {
            if keyPath == #keyPath(pvMediaPlayer.audioPlayer.state) {
                
            }
        }
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
            self.view.constraints[index].constant = tabbarVC.playerView.isHidden ? 0.0 : tabbarVC.playerView.frame.height
        }
    }
}
