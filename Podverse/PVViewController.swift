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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadNowPlayingBar()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.plain, target:nil, action:nil)
    }
    
    // TODO: why is this broke on the EpisodeTableVC? 
    // Why is self.view.bounds.size.height 554 on PodcastTableVC, but 667 on EpisodeTableVC??
    func loadNowPlayingBar() { // thanks sanjeet https://stackoverflow.com/a/38157137/2608858
        
        if self.view.viewWithTag(100) == nil {
            if let currentItem = playerHistoryManager.historyItems.first {
                
                let nowPlayingBar:UIView = UIView(frame: CGRect(x: 0, y: self.view.bounds.size.height - 51, width: self.view.bounds.size.width, height: 51))
                nowPlayingBar.tag = 100
                nowPlayingBar.backgroundColor = UIColor.white
                
                let topDivider:UIView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: 1))
                topDivider.backgroundColor = UIColor.lightGray
                nowPlayingBar.addSubview(topDivider)
                
                let podcastView:UIView = UIView(frame: CGRect(x: 0, y: 1, width: self.view.bounds.size.width - 43, height: 49))
                nowPlayingBar.addSubview(podcastView)
                
                let podcastImageView:UIImageView = UIImageView(frame: CGRect(x: 0, y:0, width: 49, height: 49))
                DispatchQueue.global().async {
                    Podcast.retrievePodcastUIImage(item: currentItem) { (podcastImage) -> Void in
                        DispatchQueue.main.async {
                            podcastImageView.image = podcastImage
                        }
                    }
                }
                podcastView.addSubview(podcastImageView)

                let podcastTitle = UILabel(frame: CGRect(x:53, y:3, width: self.view.bounds.size.width - 106, height: 24))
                podcastTitle.textAlignment = .center
                podcastTitle.font = podcastTitle.font.withSize(14)
                podcastTitle.text = currentItem.podcastTitle
                podcastView.addSubview(podcastTitle)
                
                let episodeTitle = UILabel(frame: CGRect(x:53, y:24, width: self.view.bounds.size.width - 106, height: 24))
                episodeTitle.textAlignment = .center
                episodeTitle.font = episodeTitle.font.withSize(14)
                episodeTitle.textColor = UIColor.darkGray
                episodeTitle.text = currentItem.episodeTitle
                podcastView.addSubview(episodeTitle)

                let podcastViewGesture = UITapGestureRecognizer(target: self, action: #selector (segueToNowPlaying))
                podcastView.addGestureRecognizer(podcastViewGesture)
                
                let playPause = UIButton(frame: CGRect(x: self.view.bounds.width - 46, y:4, width: 43, height: 43))
                playPause.setTitleColor(UIColor.gray, for: .normal)
                
                if (pvMediaPlayer.avPlayer.rate > 0) {
                    playPause.setImage(UIImage(named: "Pause"), for: .normal)
                } else {
                    playPause.setImage(UIImage(named: "Play"), for: .normal)
                }
                
                // TODO: why does this playOrPause selector fail? how do we fix it?
                let playPauseGesture = UITapGestureRecognizer(target: self, action: #selector (pvMediaPlayer.playOrPause))
                playPause.addGestureRecognizer(playPauseGesture)
                nowPlayingBar.addSubview(playPause)
                
                let bottomDivider:UIView = UIView(frame: CGRect(x: 0, y: 50, width: self.view.bounds.size.width, height: 1))
                bottomDivider.backgroundColor = UIColor.lightGray
                nowPlayingBar.addSubview(bottomDivider)
                
                self.view!.addSubview(nowPlayingBar)
                
            }
        }
        

        
    }
    
    func segueToNowPlaying() {
        performSegue(withIdentifier: TO_PLAYER_SEGUE_ID, sender: nil)
    }
    
}
