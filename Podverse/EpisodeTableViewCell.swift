//
//  EpisodeTableViewCell.swift
//  Podverse
//
//  Created by Mitchell Downey on 5/6/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

import UIKit

class EpisodeTableViewCell: UITableViewCell {
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var summary: UILabel!
    @IBOutlet weak var duration: UILabel!
    @IBOutlet weak var pubDate: UILabel!
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func awakeFromNib() {
        self.activityIndicator.hidesWhenStopped = true
    }
}
