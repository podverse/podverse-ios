//
//  NowPlayingBar.swift
//  Podverse
//
//  Created by Mitchell Downey on 7/15/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

import UIKit

protocol NowPlayingBarDelegate:class {
    func didTapView()
}

class NowPlayingBar:UIView {
    @IBOutlet weak var podcastImageView: UIImageView!
    @IBOutlet weak var podcastTitleLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var episodeTitle: UILabel!
    
    weak var delegate:NowPlayingBarDelegate?
    
    var isPlaying:Bool = false {
        didSet {
            playButton.setImage(UIImage(named:self.isPlaying ? "Pause" : "Play"), for: .normal)
        }
    }
    
    @IBAction func didTapView(_ sender: Any) {
        self.delegate?.didTapView()
    }
    
    @IBAction func playPause(_ sender: Any) {
       self.isPlaying = PVMediaPlayer.shared.playOrPause()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
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
}
