//
//  UITabbarController+PlayerView.swift
//  Podverse
//
//  Created by Creon Creonopoulos on 7/16/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

import UIKit

protocol PlayerViewProtocol {
    func setupPlayerBar()
    func hidePlayerView()
    func showPlayerView()
    func goToNowPlaying()
    var playerView:NowPlayingBar {get}
}

private var pvAssociationKey: UInt8 = 0

extension UITabBarController:PlayerViewProtocol {

    var playerView:NowPlayingBar {
        get {
            return objc_getAssociatedObject(self, &pvAssociationKey) as! NowPlayingBar
        }
        set(newValue) {
            objc_setAssociatedObject(self, &pvAssociationKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        self.playerView = NowPlayingBar()
        setupPlayerBar()
    }
    
    func setupPlayerBar() {
        self.playerView.frame = CGRect(x: self.tabBar.frame.minX, 
                                       y: self.tabBar.frame.minY - NowPlayingBar.playerHeight, 
                                       width: self.tabBar.frame.width, 
                                       height: NowPlayingBar.playerHeight)
        
        self.view.addSubview(self.playerView)
        self.playerView.delegate = self
    }
    
    func hidePlayerView() {
        self.playerView.isHidden = true
        PVViewController.delegate?.adjustTableView()
    }
    
    func showPlayerView() {
        self.playerView.isHidden = false
        PVViewController.delegate?.adjustTableView()
    }
    
    func goToNowPlaying() {
        if let mediaPlayerVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MediaPlayerVC") as? MediaPlayerViewController, let currentNavVC = self.selectedViewController?.childViewControllers.first?.navigationController {
            currentNavVC.pushViewController(mediaPlayerVC, animated: true)
        }

    }
}

extension UITabBarController:NowPlayingBarDelegate {
    func didTapView() {
        goToNowPlaying()
    }
}
