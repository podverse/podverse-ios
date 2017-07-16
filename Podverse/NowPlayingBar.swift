//
//  NowPlayingBar.swift
//  Podverse
//
//  Created by Mitchell Downey on 7/15/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

import UIKit

class NowPlayingBar: UIView {

    @IBOutlet var contentView: UIView!
    @IBOutlet weak var podcastTitle: UILabel!
    @IBOutlet weak var episodeTitle: UILabel!
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var button: UIButton!

    override init(frame: CGRect) {
        super.init(frame: frame)
        nibSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        nibSetup()
    }
    
    private func nibSetup() {
        backgroundColor = .white
        
        Bundle.main.loadNibNamed("NowPlayingBar", owner: self, options: nil)
        contentView.frame = bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        contentView.translatesAutoresizingMaskIntoConstraints = true
        
        addSubview(contentView)
    }
    
}
