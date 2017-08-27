//
//  AddToPlaylistViewController.swift
//  Podverse
//
//  Created by Mitchell Downey on 8/26/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

import UIKit

class AddToPlaylistViewController: UIViewController {

    var playerHistoryItem: PlayerHistoryItem?
    var shouldSaveFullEpisode = false
    
    @IBOutlet weak var clipTitle: UILabel!
    @IBOutlet weak var episodePubDate: UILabel!
    @IBOutlet weak var episodeTitle: UILabel!
    @IBOutlet weak var podcastTitle: UILabel!
    @IBOutlet weak var podcastImage: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var time: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let item = playerHistoryItem {
            
            self.podcastTitle.text = item.podcastTitle
            
            self.episodeTitle.text = item.episodeTitle
            
            if shouldSaveFullEpisode {
                self.clipTitle.text = "Full Episode"
                self.time.text = "--:--"
            } else {
                self.clipTitle.text = item.clipTitle
                
                if let time = item.readableStartAndEndTime() {
                    self.time.text = time
                }
            }
                        
            if let episodePubDate = item.episodePubDate {
                self.episodePubDate.text = episodePubDate.toShortFormatString()
            }
            
            Podcast.retrievePodcastImage(podcastImageURLString: item.podcastImageUrl) { (podcastImage) -> Void in
                DispatchQueue.main.async {
                    if let podcastImage = podcastImage {
                        self.podcastImage.image = podcastImage
                    }
                }
            }
            
        }
        
    }
    
}
