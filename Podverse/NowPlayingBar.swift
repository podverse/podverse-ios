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
        addObservers()
        self.activityIndicator.hidesWhenStopped = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
        addObservers()
        self.activityIndicator.hidesWhenStopped = true
    }
    
    deinit {
        removeObservers()
    }
    
    fileprivate func addObservers() {
        self.addObserver(self, forKeyPath: #keyPath(audioPlayer.state), options: [.new], context: nil)
    }
    
    fileprivate func removeObservers() {
        self.removeObserver(self, forKeyPath: #keyPath(audioPlayer.state))
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
            if self.audioPlayer.state == STKAudioPlayerState.buffering || self.audioPlayer.state == STKAudioPlayerState.error || self.pvMediaPlayer.shouldSetupClip {
                self.activityIndicator.startAnimating()
                self.playButton.isHidden = true
            } else if self.audioPlayer.state == STKAudioPlayerState.playing {
                self.activityIndicator.stopAnimating()
                self.playButton.setImage(UIImage(named:"Pause"), for: .normal)
                self.playButton.isHidden = false
            } else {
                self.activityIndicator.stopAnimating()
                self.playButton.setImage(UIImage(named:"Play"), for: .normal)
                self.playButton.isHidden = false
            }
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let keyPath = keyPath {
            if keyPath == #keyPath(audioPlayer.state) {
                if self.audioPlayer.state == STKAudioPlayerState.playing || audioPlayer.state == STKAudioPlayerState.paused {
                    self.togglePlayIcon()
                }
                
                if self.audioPlayer.state == STKAudioPlayerState.error {
                    print("ERROR AUDIOPLAYER ERROR STATE")
                }
            }
        }
    }
}

extension NowPlayingBar:PVMediaPlayerUIDelegate {
    
    func mediaPlayerButtonStateChanged(showPlayerButton: Bool) {}
    
    func playerHistoryItemLoadingBegan() {
        self.togglePlayIcon()
    }
    
    func playerHistoryItemLoaded() {
        self.togglePlayIcon()
    }
    
}
