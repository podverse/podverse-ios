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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.designNowPlayingBar()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.plain, target:nil, action:nil)
    }
    
    func designNowPlayingBar() { // thanks sanjeet https://stackoverflow.com/a/38157137/2608858
        
        if let currentItem = playerHistoryManager.historyItems.first {
            
            let nowPlayingBar:UIView = UIView(frame: CGRect(x: 0, y: self.view.bounds.size.height - 200, width: self.view.bounds.size.width, height: 51))
            nowPlayingBar.backgroundColor = UIColor.white
            
            let topDivider:UIView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: 1))
            topDivider.backgroundColor = UIColor.lightGray
            nowPlayingBar.addSubview(topDivider)
            
            let podcastTitle = UILabel(frame: CGRect(x:0, y:4, width: self.view.bounds.size.width, height: 24))
            podcastTitle.textAlignment = .center
            podcastTitle.font = podcastTitle.font.withSize(16)
            podcastTitle.text = currentItem.podcastTitle
            nowPlayingBar.addSubview(podcastTitle)
            
            let episodeTitle = UILabel(frame: CGRect(x:0, y:24, width: self.view.bounds.size.width, height: 24))
            episodeTitle.textAlignment = .center
            episodeTitle.font = episodeTitle.font.withSize(16)
            episodeTitle.textColor = UIColor.darkGray
            episodeTitle.text = currentItem.episodeTitle
            nowPlayingBar.addSubview(episodeTitle)
            
            let bottomDivider:UIView = UIView(frame: CGRect(x: 0, y: 50, width: self.view.bounds.size.width, height: 1))
            bottomDivider.backgroundColor = UIColor.lightGray
            nowPlayingBar.addSubview(bottomDivider)
            
            let gesture = UITapGestureRecognizer(target: self, action: #selector (self.segueToNowPlaying))
            nowPlayingBar.addGestureRecognizer(gesture)
            
            self.view!.addSubview(nowPlayingBar)
            
        }
        
    }

}
