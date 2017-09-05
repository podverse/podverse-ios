//
//  MakeClipTitleViewController.swift
//  Podverse
//
//  Created by Mitchell Downey on 8/31/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

import UIKit

class MakeClipTitleViewController: UIViewController, UITextViewDelegate {

    var endTime: Int?
    var playerHistoryItem: PlayerHistoryItem?
    var startTime: Int?
    
    @IBOutlet weak var duration: UILabel!
    @IBOutlet weak var endTimeLabel: UILabel!
    @IBOutlet weak var episodeTitle: UILabel!
    @IBOutlet weak var podcastImage: UIImageView!
    @IBOutlet weak var podcastTitle: UILabel!
    @IBOutlet weak var startTimeLabel: UILabel!
    @IBOutlet weak var titleInput: UITextView!
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if (text == "\n") {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
    @IBAction func save(_ sender: Any) {
        
        if let mediaRefItem = self.playerHistoryItem?.copyPlayerHistoryItem() {
            
            if let startTime = self.startTime {
                mediaRefItem.startTime = Int64(startTime)
            }
            
            if let endTime = self.endTime {
                mediaRefItem.endTime = Int64(endTime)
            }
            
            if let title = self.titleInput.text {
                mediaRefItem.clipTitle = title
            }
            
            mediaRefItem.saveToServerAsMediaRef() { mediaRef in
                print("hello")
            }
            
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let item = playerHistoryItem {
            
            self.podcastTitle.text = item.podcastTitle
            self.episodeTitle.text = item.episodeTitle
            
            self.podcastImage.image = Podcast.retrievePodcastImage(podcastImageURLString: item.podcastImageUrl, feedURLString: item.podcastFeedUrl) { (podcastImage) -> Void in
                self.podcastImage.image = podcastImage
            }
            
            if let startTime = self.startTime {
                self.startTimeLabel.text = "Start: " + PVTimeHelper.convertIntToHMSString(time: startTime)
            } else {
                self.startTimeLabel.text = ""
            }
            
            if let endTime = self.endTime {
                self.endTimeLabel.text = "End: " + PVTimeHelper.convertIntToHMSString(time: endTime)
            } else {
                self.endTimeLabel.text = "End:"
            }
            
            if let startTime = self.startTime, let endTime = self.endTime {
                self.duration.text = "Duration: " + PVTimeHelper.convertIntToReadableHMSDuration(seconds: endTime - startTime)
            } else {
                self.duration.text = "Duration:"
            }
        }
        
    }
    
    
}
