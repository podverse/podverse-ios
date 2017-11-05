//
//  NowPlayingBar.swift
//  Podverse
//
//  Created by Mitchell Downey on 7/15/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

import UIKit
import StreamingKit

protocol NowPlayingBarDelegate:class {
    func didTapView()
}

class NowPlayingBar:UIView {
    @IBOutlet weak var podcastImageView: UIImageView!
    @IBOutlet weak var podcastTitleLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var episodeTitle: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    weak var delegate:NowPlayingBarDelegate?
    
    let pvMediaPlayer = PVMediaPlayer.shared
    let audioPlayer = PVMediaPlayer.shared.audioPlayer
    
    @IBAction func didTapView(_ sender: Any) {
        self.delegate?.didTapView()
    }
    
    @IBAction func playPause(_ sender: Any) {
       PVMediaPlayer.shared.playOrPause()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        self.activityIndicator.hidesWhenStopped = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
        self.activityIndicator.hidesWhenStopped = true
    }
    
    private func setupView() {
        let view = viewFromNibForClass()
        view.frame = bounds
        
        view.autoresizingMask = [
            UIViewAutoresizing.flexibleWidth,
            UIViewAutoresizing.flexibleHeight
        ]
        
        addSubview(view)
    }
    
    private func viewFromNibForClass() -> UIView {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: String(describing: type(of: self)), bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil).first as! UIView
        
        return view
    }
    
    static var playerHeight:CGFloat {
        return 60.0 
    }
    
    func togglePlayIcon() {
        DispatchQueue.main.async {
            if self.audioPlayer.state == .stopped || self.audioPlayer.state == .paused {
                self.activityIndicator.isHidden = true
                self.playButton.setImage(UIImage(named:"play"), for: .normal)
                self.playButton.isHidden = false
            } else if self.audioPlayer.state == .error {
                self.activityIndicator.isHidden = true
                self.playButton.setImage(UIImage(named:"AppIcon"), for: .normal)
                self.playButton.isHidden = false
            } else if self.audioPlayer.state == .playing && !self.pvMediaPlayer.shouldSetupClip {
                self.activityIndicator.isHidden = true
                self.playButton.setImage(UIImage(named:"pause"), for: .normal)
                self.playButton.isHidden = false
            } else if self.audioPlayer.state == .buffering || self.pvMediaPlayer.shouldSetupClip {
                self.activityIndicator.isHidden = false
                self.playButton.isHidden = true
            } else {
                self.activityIndicator.isHidden = true
                self.playButton.setImage(UIImage(named:"play"), for: .normal)
                self.playButton.isHidden = false
            }
        }
    }
    
}

extension NowPlayingBar:PVMediaPlayerUIDelegate {
    
    func playerHistoryItemBuffering() {
        self.togglePlayIcon()
    }
    
    func playerHistoryItemErrored() {
        self.togglePlayIcon()
    }
    
    func playerHistoryItemLoaded() {
        self.togglePlayIcon()
    }
    
    func playerHistoryItemLoadingBegan() {
        self.togglePlayIcon()
    }
    
    func playerHistoryItemPaused() {
        self.togglePlayIcon()
    }
    
}
