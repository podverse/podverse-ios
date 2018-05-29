//
//  MakeClipTimeViewController.swift
//  Podverse
//
//  Created by Mitchell Downey on 8/26/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

import StreamingKit
import UIKit

class MakeClipTimeViewController: UIViewController, UITextFieldDelegate {
    
    let audioPlayer = PVMediaPlayer.shared.audioPlayer
    var endTime: Int?
    var endTimePreview: Int?
    var playerHistoryItem: PlayerHistoryItem?
    let pvMediaPlayer = PVMediaPlayer.shared
    var startTime: Int?
    var timer: Timer?
    var isPublic = false

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var currentTime: UILabel!
    @IBOutlet weak var duration: UILabel!
    @IBOutlet weak var endPreview: UIButton!
    @IBOutlet weak var playbackControlView: UIView!
    @IBOutlet weak var progress: UISlider!
    @IBOutlet weak var startPreview: UIButton!
    @IBOutlet weak var play: UIImageView!
    @IBOutlet weak var visibilityButton: UIButton!
    @IBOutlet weak var clearEndTimeButton: UIButton!
    @IBOutlet weak var titleInput: UITextField!
    @IBOutlet weak var startTimeLabel: UILabel!
    @IBOutlet weak var endTimeLabel: UILabel!
    @IBOutlet weak var startTimeInputView: UIView!
    @IBOutlet weak var endTimeInputView: UIView!
    @IBOutlet weak var loadingOverlay: UIView!
    @IBOutlet weak var loadingActivityInidicator: UIActivityIndicatorView!
    @IBOutlet weak var grabHintImage: UIImageView!
    @IBOutlet weak var podcastImage: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupTimer()
        populatePlayerInfo()
        
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"Back", style:.plain, target:nil, action:nil)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(save))
        
        self.activityIndicator.startAnimating()
        self.progress.setThumbImage(#imageLiteral(resourceName: "SliderCurrentPosition"), for: .normal)
        self.startTimeLabel.text = PVTimeHelper.convertIntToHMSString(time: self.startTime)
        self.clearEndTimeButton.isHidden = true
        self.endTimeLabel.text = "optional"
        self.endTimeLabel.textColor = UIColor.lightGray        
        self.titleInput.leftView = UIView(frame: CGRect(x:0, y:0, width:10, height:35))
        self.titleInput.leftViewMode = UITextFieldViewMode.always
        self.titleInput.returnKeyType = .done
        self.podcastImage.image = Podcast.retrievePodcastImage(fullSized: true, podcastImageURLString: self.pvMediaPlayer.nowPlayingItem?.podcastImageUrl, feedURLString: nil, completion: { (image) in
            self.podcastImage.image = image
        })
        
        self.loadingOverlay.isHidden = true
        self.loadingActivityInidicator.hidesWhenStopped = true
        
        if let savedVisibilityType = UserDefaults.standard.value(forKey: kMakeClipVisibilityType) as? String, let visibilityType = VisibilityOptions(rawValue: savedVisibilityType) {
            self.visibilityButton.setTitle(visibilityType.text + " ▼", for: .normal)
            self.isPublic = visibilityType == VisibilityOptions.isPublic ? true : false
        } else {
            self.visibilityButton.setTitle(VisibilityOptions.isPublic.text + " ▼", for: .normal)
            self.isPublic = true
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch:UITouch = touches.first!
        if touch.view == self.grabHintImage {
            self.grabHintImage.isHidden = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        self.pvMediaPlayer.delegate = self
        togglePlayIcon()
        updateTime()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    deinit {
        removeTimer()
    }
    
    @IBAction func sliderAction(_ sender: Any, forEvent event: UIEvent) {
        if let sender = sender as? UISlider, let touchEvent = event.allTouches?.first {
            switch touchEvent.phase {
            case .began:
                removeTimer()
            case .ended:
                if let duration = pvMediaPlayer.duration {
                    let newTime = Double(sender.value) * duration
                    self.pvMediaPlayer.seek(toTime: newTime)
                    updateTime()
                }
                setupTimer()
            default:
                break
            }
        }
    }
    
    @IBAction func startTimePreview(_ sender: Any) {
        if let startTime = self.startTime {
            self.pvMediaPlayer.seek(toTime: Double(startTime))
            self.pvMediaPlayer.play()
        }
        
        if let endTime = self.endTime {
            self.pvMediaPlayer.shouldStopAtEndTime = Int64(endTime)
        }
    }
    
    @IBAction func endTimePreview(_ sender: Any) {
        if let endTime = self.endTime {
            self.endTimePreview = endTime
            
            self.pvMediaPlayer.seek(toTime: (endTime < 3) ? 0 : Double(endTime) - 3)
            self.pvMediaPlayer.play()
        }
    }
    
    @IBAction func timeJumpBackward(_ sender: Any) {
        let newTime = self.pvMediaPlayer.progress - 15
        
        if newTime >= 14 {
            self.pvMediaPlayer.seek(toTime: newTime)
        } else {
            self.pvMediaPlayer.seek(toTime: 0)
        }
        
        updateTime()
    }
    
    @IBAction func timeJumpForward(_ sender: Any) {
        let newTime = self.pvMediaPlayer.progress + 15
        self.pvMediaPlayer.seek(toTime: newTime)
        updateTime()
    }
    
    @IBAction func setStartTime(_ sender: Any) {
        let currentTime = Int(self.pvMediaPlayer.progress)
        self.startTime = Int(currentTime)
        self.startTimeLabel.text = PVTimeHelper.convertIntToHMSString(time: currentTime)
    }

    @IBAction func setEndTime(_ sender: Any) {
        let currentTime = Int(self.pvMediaPlayer.progress)
        self.endTime = Int(currentTime)
        self.endTimeLabel.text = PVTimeHelper.convertIntToHMSString(time: currentTime)
        self.endTimeLabel.textColor = UIColor.black
        self.clearEndTimeButton.isHidden = false
    }
    
    @IBAction func clearEndTime(_ sender: Any) {
        self.endTime = nil
        self.endTimeLabel.text = "optional"
        self.endTimeLabel.textColor = UIColor.lightGray
        self.clearEndTimeButton.isHidden = true
    }
        
    @IBAction func showVisibilityMenu(_ sender: Any) {
        let visibilityActions = UIAlertController(title: "Clip Visibility", message: nil, preferredStyle: .actionSheet)
        
        visibilityActions.addAction(UIAlertAction(title: VisibilityOptions.isPublic.text, style: .default, handler: { action in
            self.isPublic = true
            UserDefaults.standard.set(VisibilityOptions.isPublic.text, forKey: kMakeClipVisibilityType)
            self.visibilityButton.setTitle(VisibilityOptions.isPublic.text + " ▼", for: .normal)
            
        }
        ))
        
        visibilityActions.addAction(UIAlertAction(title: VisibilityOptions.isOnlyWithLink.text, style: .default, handler: { action in
            self.isPublic = false
            UserDefaults.standard.set(VisibilityOptions.isOnlyWithLink.text, forKey: kMakeClipVisibilityType)
            self.visibilityButton.setTitle(VisibilityOptions.isOnlyWithLink.text + " ▼", for: .normal)
        }
        ))
        
        visibilityActions.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(visibilityActions, animated: true, completion: nil)
    }
    
    @objc func save() {
        self.view.endEditing(true)
        
        guard let startTime = self.startTime else {
            let alertController = UIAlertController(title: "Invalid Clip Time", message: "Start time must be provided.", preferredStyle: .alert)
            let action = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(action)
            self.present(alertController, animated: true, completion: nil)
            return
        }
        
        if let endTime = self.endTime {
            
            var alertMessage = "Start time is later than end time."
            if startTime == endTime {
                alertMessage = "Start time is equal to end time."
            }
            
            if startTime == endTime || startTime >= endTime {
                let alertController = UIAlertController(title: "Invalid Clip Time", message: alertMessage, preferredStyle: .alert)
                let action = UIAlertAction(title: "OK", style: .default, handler: nil)
                alertController.addAction(action)
                self.present(alertController, animated: true, completion: nil)
                return
            }
            
        }
        
        if let mediaRefItem = self.playerHistoryItem?.copyPlayerHistoryItem() {
            
            showLoadingOverlay()
            
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
                self.hideLoadingOverlay()
                if let id = mediaRef?.id {
                    self.displayClipCreatedAlert(mediaRefId: id)
                } else {
                    self.displayFailedToCreateClipAlert()
                }
            }
        }
    }
    
    private func showLoadingOverlay() {
        self.loadingOverlay.isHidden = false
        self.loadingActivityInidicator.startAnimating()
    }
    
    private func hideLoadingOverlay() {
        self.loadingOverlay.isHidden = true
        self.loadingActivityInidicator.stopAnimating()
    }
    
    private func displayClipCreatedAlert(mediaRefId: String) {
        
        let actions = UIAlertController(title: "Clip Created", 
                                        message: BASE_URL + "clips/" + mediaRefId, 
                                        preferredStyle: .alert)
        
        actions.addAction(UIAlertAction(title: "Share", style: .default, handler: { action in
            let clipUrlItem = [BASE_URL + "clips/" + mediaRefId]
            let activityVC = UIActivityViewController(activityItems: clipUrlItem, applicationActivities: nil)
            activityVC.popoverPresentationController?.sourceView = self.view
            
            activityVC.completionWithItemsHandler = { activityType, success, items, error in
                if activityType == UIActivityType.copyToPasteboard {
                    self.showToast(message: kLinkCopiedToast)
                }
                
                self.navigationController?.popViewController(animated: true)
            }
            
            self.present(activityVC, animated: true, completion: nil)
        }))
        
        actions.addAction(UIAlertAction(title: "Done", style: .cancel, handler: { action in
            self.navigationController?.popViewController(animated: true)
        }))
        
        self.present(actions, animated: true, completion: nil)
    }
    
    private func displayFailedToCreateClipAlert() {
        
        let actions = UIAlertController(title: "Failed to create clip",
                                        message: "Please check your internet connection and try again.",
                                        preferredStyle: .alert)
        
        actions.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: { action in
            self.navigationController?.popViewController(animated: true)
        }))
        
        self.present(actions, animated: true, completion: nil)
    }
    
    private func setupTimer() {
        self.timer = Timer.scheduledTimer(timeInterval: 0.25, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
    }
    
    private func removeTimer() {
        if let timer = self.timer {
            timer.invalidate()
        }
    }
    
    private func populatePlayerInfo() {
        if let dur = pvMediaPlayer.duration {
            duration.text = Int64(dur).toMediaPlayerString()
        }
    }
    
    func togglePlayIcon() {
        
        // Grab audioPlayer each time to ensure we are checking the correct state
        let audioPlayer = PVMediaPlayer.shared.audioPlayer
        
        if audioPlayer.state == .stopped || audioPlayer.state == .paused {
            self.activityIndicator.isHidden = true
            self.play.image = UIImage(named:"play")
            self.play.tintColor = UIColor.black
            self.play.isHidden = false
        } else if audioPlayer.state == .error {
            self.activityIndicator.isHidden = true
            self.play.image = UIImage(named:"playerror")?.withRenderingMode(.alwaysTemplate)
            self.play.tintColor = UIColor.red
            self.play.isHidden = false
        } else if audioPlayer.state == .playing && !self.pvMediaPlayer.shouldSetupClip {
            self.activityIndicator.isHidden = true
            self.play.image = UIImage(named:"pause")
            self.play.tintColor = UIColor.black
            self.play.isHidden = false
        } else if audioPlayer.state == .buffering || self.pvMediaPlayer.shouldSetupClip {
            self.activityIndicator.isHidden = false
            self.play.isHidden = true
        } else {
            self.activityIndicator.isHidden = true
            self.play.image = UIImage(named:"play")
            self.play.tintColor = UIColor.black
            self.play.isHidden = false
        }
    }
    
    @objc func updateTime () {
        var playbackPosition = Double(0)
        if self.pvMediaPlayer.progress > 0 {
            playbackPosition = self.pvMediaPlayer.progress
        } else if let dur = self.pvMediaPlayer.duration {
            playbackPosition = Double(self.progress.value) * dur
        }
        
        self.currentTime.text = Int64(playbackPosition).toMediaPlayerString()
        
        if let dur = self.pvMediaPlayer.duration {
            self.duration.text = Int64(dur).toMediaPlayerString()
            self.progress.value = Float(playbackPosition / dur)
        }
        
        if let endTimePreview = self.endTimePreview {
            if Int(self.pvMediaPlayer.progress) >= endTimePreview {
                self.pvMediaPlayer.pause()
                self.endTimePreview = nil
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func sliderTapped(_ sender: Any) {
        pvMediaPlayer.playOrPause()
    }
    
    @IBAction func slidingRecognized(_ sender: Any) {
        if let pan = sender as? UIPanGestureRecognizer, let duration = pvMediaPlayer.duration {
            
            if !pvMediaPlayer.playerIsLoaded() {
                let panPoint = pan.velocity(in: self.playbackControlView)
                let newTime = ((Double(self.progress.value) * duration) + Double(panPoint.x / 180.0))
                self.progress.value = Float(newTime / duration)
                self.pvMediaPlayer.seek(toTime: newTime)
                updateTime()
            } else {
                let panPoint = pan.velocity(in: self.playbackControlView)
                var newTime = (self.pvMediaPlayer.progress + Double(panPoint.x / 180.0))
                
                if newTime <= 0 {
                    newTime = 0
                }
                else if newTime >= duration {
                    newTime = duration - 1
                    self.audioPlayer.pause()
                }
                
                self.pvMediaPlayer.seek(toTime: newTime)
                updateTime()
            }
            
        }
    }
}

extension MakeClipTimeViewController:PVMediaPlayerUIDelegate {
    
    func playerHistoryItemBuffering() {
        self.togglePlayIcon()
    }
    
    func playerHistoryItemErrored() {
        self.togglePlayIcon()
    }
    
    func playerHistoryItemLoaded() {
        DispatchQueue.main.async {
            self.updateTime()
            self.togglePlayIcon()
        }
        
    }
    
    func playerHistoryItemLoadingBegan() {
        DispatchQueue.main.async {
            self.togglePlayIcon()
        }
    }
    
    func playerHistoryItemPaused() {
        self.togglePlayIcon()
    }
    
}
