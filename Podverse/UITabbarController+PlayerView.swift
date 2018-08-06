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
    func goToNowPlaying(isDataAvailable:Bool)
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
        var extraIphoneXSpace:CGFloat = 0.0
        if (UIScreen.main.nativeBounds.height == 2436.0) {
            extraIphoneXSpace = 33.0
        }
        
        self.playerView.frame = CGRect(x: self.tabBar.frame.minX, 
                                       y: self.tabBar.frame.minY - NowPlayingBar.playerHeight - extraIphoneXSpace, 
                                       width: self.tabBar.frame.width, 
                                       height: NowPlayingBar.playerHeight)
        self.playerView.isHidden = true
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
    
    func goToNowPlaying(isDataAvailable:Bool = true) {
        if let currentNavVC = self.selectedViewController?.childViewControllers.first?.navigationController {
            
            var optionalMediaPlayerVC: MediaPlayerViewController?
            
            for controller in currentNavVC.viewControllers {
                if controller.isKind(of: MediaPlayerViewController.self) {
                    optionalMediaPlayerVC = controller as? MediaPlayerViewController
                    break
                }
            }
            
            if let mediaPlayerVC = optionalMediaPlayerVC {
                currentNavVC.popToViewController(mediaPlayerVC, animated: false)
            } else if let mediaPlayerVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MediaPlayerVC") as? MediaPlayerViewController {
                PVMediaPlayer.shared.isDataAvailable = isDataAvailable
                if !isDataAvailable {
                    PVMediaPlayer.shared.shouldAutoplayOnce = true
                }

                currentNavVC.pushViewController(mediaPlayerVC, animated: true)
            }
        }
    }
    
    func goToClips(_ clipFilter:ClipFilter? = nil, _ clipSorting:ClipSorting? = nil) {
        if let currentNavVC = self.selectedViewController?.childViewControllers.first?.navigationController {
            
            var optionalClipsTVC: ClipsTableViewController?
            
            for controller in currentNavVC.viewControllers {
                if controller.isKind(of: ClipsTableViewController.self) {
                    optionalClipsTVC = controller as? ClipsTableViewController
                    break
                }
            }
            
            if let clipFilter = clipFilter {
                UserDefaults.standard.set(clipFilter.rawValue, forKey: kClipsTableFilterType)
            } else {
                UserDefaults.standard.set(ClipFilter.allPodcasts.rawValue, forKey: kClipsTableFilterType)
            }
            
            if let clipSorting = clipSorting {
                UserDefaults.standard.set(clipSorting.rawValue, forKey: kClipsTableSortingType)
            } else {
                UserDefaults.standard.set(ClipSorting.topWeek.rawValue, forKey: kClipsTableFilterType)
            }
            
            if let clipsTVC = optionalClipsTVC {
                clipsTVC.shouldOverrideQuery = true
                currentNavVC.popToViewController(clipsTVC, animated: false)
            } else if let clipsTVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ClipsTVC") as? ClipsTableViewController {
                currentNavVC.pushViewController(clipsTVC, animated: false)
            }
        }
    }
    
}

extension UITabBarController:NowPlayingBarDelegate {
    func didTapView() {
        goToNowPlaying()
    }
}
