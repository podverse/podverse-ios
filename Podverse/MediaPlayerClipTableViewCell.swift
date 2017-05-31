//
//  MediaPlayerClipTableViewCell.swift
//  Podverse
//
//  Created by Creon Creonopoulos on 5/30/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

import UIKit

class MediaPlayerClipTableViewCell: UITableViewCell {
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.contentView.layer.borderWidth = 0.8
        self.contentView.layer.borderColor = UIColor.white.cgColor
        self.contentView.layer.cornerRadius = 8.0
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.contentView.frame = UIEdgeInsetsInsetRect(self.contentView.frame, UIEdgeInsetsMake(2, 0, 2, 0))
    }
}
