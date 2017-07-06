//
//  DownloadTableViewCell.swift
//  Podverse
//
//  Created by Mitchell Downey on 7/4/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

import UIKit

class DownloadTableViewCell: UITableViewCell {

    @IBOutlet weak var podcastImage: UIImageView!
    @IBOutlet weak var episodeTitle: UILabel!
    @IBOutlet weak var podcastTitle: UILabel!
    @IBOutlet weak var progress: UIProgressView!
    @IBOutlet weak var progressStats: UILabel!
    @IBOutlet weak var status: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
