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
    
    var isPublic = false
    let pvMediaPlayer = PVMediaPlayer.shared
    var endTime: Int?
    var playerHistoryItem: PlayerHistoryItem?
    var startTime: Int?
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var play: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var titleInput: UITextView!
    @IBOutlet weak var visibilityButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.pvMediaPlayer.delegate = self
        
        if let savedVisibilityType = UserDefaults.standard.value(forKey: kMakeClipVisibilityType) as? String, let visibilityType = VisibilityOptions(rawValue: savedVisibilityType) {
            self.visibilityButton.setTitle(visibilityType.text, for: .normal)
            self.isPublic = visibilityType == VisibilityOptions.isPublic ? true : false
        } else {
            self.visibilityButton.setTitle(VisibilityOptions.isPublic.text, for: .normal)
            self.isPublic = true
        }
        
        self.titleInput.becomeFirstResponder()
        
        self.saveButton.layer.borderWidth = 1
        self.saveButton.layer.borderColor = UIColor.lightGray.cgColor
        
        togglePlayIcon()
        
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if (text == "\n") {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
    @IBAction func isPublicTapped(_ sender: Any) {
        showVisibilityMenu()
    }
    
    @IBAction func timeSkipBackward(_ sender: Any) {
        let newTime = self.pvMediaPlayer.audioPlayer.progress - 15
        
        if newTime >= 14 {
            self.pvMediaPlayer.seek(toTime: newTime)
        } else {
            self.pvMediaPlayer.seek(toTime: 0)
        }
    }
    
    @IBAction func timeSkipForward(_ sender: Any) {
        let newTime = self.pvMediaPlayer.audioPlayer.progress + 15
        self.pvMediaPlayer.seek(toTime: newTime)
    }
    
    @IBAction func playOrPause(_ sender: Any) {
        self.pvMediaPlayer.playOrPause()
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
            
            mediaRefItem.isPublic = self.isPublic
            
            mediaRefItem.saveToServerAsMediaRef() { mediaRef in
                if let id = mediaRef?.id {
                    self.displayClipCreatedAlert(mediaRefId: id)
                }
            }
            
        }
        
    }
    
    func togglePlayIcon() {
        DispatchQueue.main.async {
            if self.pvMediaPlayer.audioPlayer.state == .stopped || self.pvMediaPlayer.audioPlayer.state == .paused {
                self.activityIndicator.isHidden = true
                self.play.setImage(UIImage(named:"play"), for: .normal)
                self.play.isHidden = false
            } else if self.pvMediaPlayer.audioPlayer.state == .error {
                self.activityIndicator.isHidden = true
                self.play.setImage(UIImage(named:"AppIcon"), for: .normal)
                self.play.isHidden = false
            } else if self.pvMediaPlayer.audioPlayer.state == .playing && !self.pvMediaPlayer.shouldSetupClip {
                self.activityIndicator.isHidden = true
                self.play.setImage(UIImage(named:"pause"), for: .normal)
                self.play.isHidden = false
            } else if self.pvMediaPlayer.audioPlayer.state == .buffering || self.pvMediaPlayer.shouldSetupClip {
                self.activityIndicator.isHidden = false
                self.play.isHidden = true
            } else {
                self.activityIndicator.isHidden = true
                self.play.setImage(UIImage(named:"play"), for: .normal)
                self.play.isHidden = false
            }
        }
    }
    
    func showVisibilityMenu() {
        
        let visibilityActions = UIAlertController(title: "Clip Visibility", message: nil, preferredStyle: .actionSheet)
        
        visibilityActions.addAction(UIAlertAction(title: VisibilityOptions.isPublic.text, style: .default, handler: { action in
                self.isPublic = true
                UserDefaults.standard.set(VisibilityOptions.isPublic.text, forKey: kMakeClipVisibilityType)
                self.visibilityButton.setTitle(VisibilityOptions.isPublic.text, for: .normal)

            }
        ))
        
        visibilityActions.addAction(UIAlertAction(title: VisibilityOptions.isOnlyWithLink.text, style: .default, handler: { action in
                self.isPublic = false
               UserDefaults.standard.set(VisibilityOptions.isOnlyWithLink.text, forKey: kMakeClipVisibilityType)
            self.visibilityButton.setTitle(VisibilityOptions.isOnlyWithLink.text, for: .normal)
            }
        ))
        
        visibilityActions.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(visibilityActions, animated: true, completion: nil)
        
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
                
                self.returnToMediaPlayer()
            }
            
            self.present(activityVC, animated: true, completion: nil)
        }))
        
        actions.addAction(UIAlertAction(title: "Done", style: .cancel, handler: { action in
            if var viewControllers = self.navigationController?.viewControllers {
                self.returnToMediaPlayer()
            }
        }))

        self.present(actions, animated: true, completion: nil)

    }
    
    private func returnToMediaPlayer() {
        if var viewControllers = self.navigationController?.viewControllers {
            viewControllers.removeLast(2)
            self.navigationController?.setViewControllers(viewControllers, animated: true)
        }
    }
    
}

extension MakeClipTitleViewController:PVMediaPlayerUIDelegate {
    
    func playerHistoryItemBuffering() {
        self.togglePlayIcon()
    }
    
    func playerHistoryItemErrored() {
        self.togglePlayIcon()
    }
    
    func playerHistoryItemLoaded() {
        self.togglePlayIcon()
    }
    
    func playerHistoryItemLoadingBegan() {
        self.togglePlayIcon()
    }
    
    func playerHistoryItemPaused() {
        self.togglePlayIcon()
    }
    
}
