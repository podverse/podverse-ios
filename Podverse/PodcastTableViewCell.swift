//
//  PodcastTableViewCell.swift
//  Podverse
//
//  Created by Creon on 12/27/16.
//  Copyright © 2016 Podverse LLC. All rights reserved.
//

import UIKit

class PodcastTableViewCell: UITableViewCell {
    
    @IBOutlet weak var autoDownloadIndicator: UILabel!
    @IBOutlet weak var lastPublishedDate: UILabel!
    @IBOutlet weak var pvImage: UIImageView!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var totalEpisodes: UILabel!

}
