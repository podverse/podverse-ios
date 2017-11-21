//
//  MakeClipTitleViewController.swift
//  Podverse
//
//  Created by Mitchell Downey on 8/31/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

import UIKit
import SDWebImage

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
    @IBOutlet weak var saveButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let item = playerHistoryItem {
            
            self.podcastTitle.text = item.podcastTitle
            self.episodeTitle.text = item.episodeTitle
            
            self.podcastImage.image = Podcast.retrievePodcastImage(podcastImageURLString: item.podcastImageUrl, feedURLString: item.podcastFeedUrl, completion: { image in
                self.podcastImage.image = image
            })
            
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
            
            self.titleInput.becomeFirstResponder()        
        }
        
        self.saveButton.layer.borderWidth = 1
        self.saveButton.layer.borderColor = UIColor.lightGray.cgColor
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if (text == "\n") {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
    @IBAction func save(_ sender: Any) {
        
        self.view.endEditing(true)
        
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
                if let id = mediaRef?.id {
                    self.displayClipCreatedAlert(mediaRefId: id)
                }
            }
            
        }
        
    }
    
    private func displayClipCreatedAlert(mediaRefId: String) {
        
        let actions = UIAlertController(title: "Clip Created", message: BASE_URL + "clips/" + mediaRefId, preferredStyle: .actionSheet)
        
        actions.addAction(UIAlertAction(title: "Share", style: .default, handler: { action in
            let clipUrlItem = [BASE_URL + "clips/" + mediaRefId]
            let activityVC = UIActivityViewController(activityItems: clipUrlItem, applicationActivities: nil)
            activityVC.popoverPresentationController?.sourceView = self.view
            
            activityVC.completionWithItemsHandler = { activityType, success, items, error in
                if activityType == UIActivityType.copyToPasteboard {
                    self.showToast(message: kLinkCopiedToast)
                }
            }
            
            self.present(activityVC, animated: true, completion: nil)
        }))
        
        actions.addAction(UIAlertAction(title: "Done", style: .cancel, handler: { action in
            if var viewControllers = self.navigationController?.viewControllers {
                viewControllers.removeLast(2)
                self.navigationController?.setViewControllers(viewControllers, animated: true)
            }
        }))

        self.present(actions, animated: true, completion: nil)

    }
    
}
