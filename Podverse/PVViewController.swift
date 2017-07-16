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
    let nowPlayingBar: NowPlayingBar? = NowPlayingBar()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadNowPlayingBar()
        showPlayerView()
        PVDeleter.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.plain, target:nil, action:nil)
    }
    
    func loadNowPlayingBar() { // thanks sanjeet https://stackoverflow.com/a/38157137/2608858
        guard let tabbarVC = self.tabBarController, !tabbarVC.view.subviews.contains(where: {$0.tag == kNowPlayingTag}) else {
            return
        }
        
//        let nowPlayingBarHeight:CGFloat = 51.0
//        nowPlayingBar.tag = playerTag
        
        if let currentItem = playerHistoryManager.historyItems.first {
            if let nowPlayingBar = nowPlayingBar {
                nowPlayingBar.podcastTitle.text = "podcast title here"
                nowPlayingBar.episodeTitle.text = "episode title here"
                nowPlayingBar.image.image = Podcast.retrievePodcastImage()
                nowPlayingBar.button.setTitle("PLAY", for: .normal)
                self.view.addSubview(nowPlayingBar)
            }
            
//
//            podcastImageView.image = Podcast.retrievePodcastImage(podcastImageURLString: currentItem.podcastFeedUrl, feedURLString: currentItem.podcastImageUrl) { (podcastImage) -> Void in
//                podcastImageView.image = podcastImage
//            }
//            
//            podcastView.addSubview(podcastImageView)
//
//            let podcastTitle = UILabel(frame: CGRect(x:54, y:3, width: self.view.bounds.size.width - 108, height: 24))
//            podcastTitle.textAlignment = .center
//            podcastTitle.font = podcastTitle.font.withSize(14)
//            podcastTitle.text = currentItem.podcastTitle
//            podcastView.addSubview(podcastTitle)
//            
//            let episodeTitle = UILabel(frame: CGRect(x:54, y:24, width: self.view.bounds.size.width - 108, height: 24))
//            episodeTitle.textAlignment = .center
//            episodeTitle.font = episodeTitle.font.withSize(14)
//            episodeTitle.textColor = UIColor.darkGray
//            episodeTitle.text = currentItem.episodeTitle
//            podcastView.addSubview(episodeTitle)
//
//            let podcastViewGesture = UITapGestureRecognizer(target: self, action: #selector (goToNowPlaying))
//            podcastView.addGestureRecognizer(podcastViewGesture)
//            
//            let playPause = UIButton(frame: CGRect(x: self.view.bounds.width - 46, y:4, width: 43, height: 43))
//            playPause.setTitleColor(UIColor.gray, for: .normal)
//            
//            if (pvMediaPlayer.avPlayer.rate > 0) {
//                playPause.setImage(UIImage(named: "Pause"), for: .normal)
//            } else {
//                playPause.setImage(UIImage(named: "Play"), for: .normal)
//            }
//            
//            let playPauseGesture = UITapGestureRecognizer(target: pvMediaPlayer, action: #selector (PVMediaPlayer.playOrPause))
//            playPause.addGestureRecognizer(playPauseGesture)
//            nowPlayingBar.addSubview(playPause)
//            
//            let bottomDivider:UIView = UIView(frame: CGRect(x: 0, y: 50, width: self.view.bounds.size.width, height: 1))
//            bottomDivider.backgroundColor = UIColor.lightGray
//            nowPlayingBar.addSubview(bottomDivider)
//            
//            nowPlayingBar.tag = playerTag
//            tabbarVC.view.addSubview(nowPlayingBar)
        }
    }
    
    func showPlayerView() {
        self.tabBarController?.view.subviews.first(where: {$0.tag == kNowPlayingTag})?.isHidden = false
    }
    
    func hidePlayerView() {
        self.tabBarController?.view.subviews.first(where: {$0.tag == kNowPlayingTag})?.isHidden = true
    }
    
    func goToNowPlaying() {
        if let mediaPlayerVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MediaPlayerVC") as? MediaPlayerViewController, let currentNavVC = self.tabBarController?.selectedViewController?.childViewControllers.first?.navigationController {
            currentNavVC.pushViewController(mediaPlayerVC, animated: true)
        }
    }
    
}

extension PVViewController:PVDeleterDelegate {
    func podcastDeleted(feedUrl: String?) {
        if let feedUrl = feedUrl {
            if playerHistoryManager.checkIfPodcastWasLastPlayed(feedUrl: feedUrl) == true {
                self.hidePlayerView()
            }
        }
    }
    
    func episodeDeleted(mediaUrl: String?) {
        if let mediaUrl = mediaUrl {
            if playerHistoryManager.checkIfEpisodeWasLastPlayed(mediaUrl: mediaUrl) == true {
                self.hidePlayerView()
            }
        }
    }
}
