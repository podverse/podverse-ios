//
//  UIViewController+MediaPlayerUI.swift
//  Podverse
//
//  Created by Creon on 12/27/16.
//  Copyright © 2016 Podverse LLC. All rights reserved.
//

import UIKit

extension UIViewController:PVMediaPlayerUIDelegate {

    // If there is a now playing episode or clip, add Now Playing button to navbar.
    func playerNavButton() -> UIBarButtonItem? {
        // TODO
        return nil
    }
    
    func mediaPlayerButtonStateChanged(showPlayerButton: Bool) {
        if showPlayerButton {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Player", style: .plain, target: self, action: #selector(segueToNowPlaying))
        }
        else {
            removeMediaPlayerButton()
        }
    }
    
    func removeMediaPlayerButton() {
        self.navigationItem.rightBarButtonItems = []
    }

    func segueToNowPlaying() {
        self.performSegue(withIdentifier: TO_PLAYER_SEGUE_ID, sender: nil)
    }
}
