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
    @IBOutlet weak var endTimeInput: UITextField!
    @IBOutlet weak var playbackControlView: UIView!
    @IBOutlet weak var progress: UISlider!
    @IBOutlet weak var setTime: UIButton!
    @IBOutlet weak var startPreview: UIButton!
    @IBOutlet weak var startTimeInput: UITextField!
    @IBOutlet weak var play: UIImageView!
    @IBOutlet weak var visibilityButton: UIButton!
    @IBOutlet weak var titleInput: UITextField!
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        togglePlayIcon()
        updateTime()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"Back", style:.plain, target:nil, action:nil)
        
        setupTimer()
        
        addObservers()
        
        self.activityIndicator.startAnimating()
        
        self.progress.setThumbImage(#imageLiteral(resourceName: "SliderCurrentPosition"), for: .normal)
        
        populatePlayerInfo()
        
        // prevent keyboard from displaying for startTimeInput and endTimeInput
        self.startTimeInput.inputView = UIView()
        self.endTimeInput.inputView = UIView()
        
        self.startTimeInput.text = PVTimeHelper.convertIntToHMSString(time: self.startTime)
        
        self.endTimeInput.layer.masksToBounds = false
        self.endTimeInput.layer.shadowRadius = 12.0
        self.endTimeInput.layer.shadowColor = UIColor.clear.cgColor
        self.endTimeInput.layer.shadowOffset = CGSize(width:1.0, height:1.0)
        self.endTimeInput.layer.shadowOpacity = 1.0
        
        self.startTimeInput.layer.masksToBounds = false
        self.startTimeInput.layer.shadowRadius = 12.0
        self.startTimeInput.layer.shadowColor = UIColor.clear.cgColor
        self.startTimeInput.layer.shadowOffset = CGSize(width:1.0, height:1.0)
        self.startTimeInput.layer.shadowOpacity = 1.0
        
        let paddingView : UIView = UIView(frame: CGRect(x:0, y:0, width:10, height:35))
        //Change your required space instaed of 5.
        self.titleInput.leftView = paddingView
        self.titleInput.leftViewMode = UITextFieldViewMode.always
        
        self.setTime.layer.borderColor = UIColor.lightGray.cgColor
                        
        if let savedVisibilityType = UserDefaults.standard.value(forKey: kMakeClipVisibilityType) as? String, let visibilityType = VisibilityOptions(rawValue: savedVisibilityType) {
            self.visibilityButton.setTitle(visibilityType.text + " ▼", for: .normal)
            self.isPublic = visibilityType == VisibilityOptions.isPublic ? true : false
        } else {
            self.visibilityButton.setTitle(VisibilityOptions.isPublic.text + " ▼", for: .normal)
            self.isPublic = true
        }
    }
    
    deinit {
        removeObservers()
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
            
            if endTime < 3 {
                self.pvMediaPlayer.seek(toTime: 0)
            } else {
                self.pvMediaPlayer.seek(toTime: Double(endTime) - 3)
            }
            
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
    
    @IBAction func setTimeTouched(_ sender: Any) {
        let currentTime = Int(self.pvMediaPlayer.progress)
        
        if self.startTimeInput.isFirstResponder {
            self.startTimeInput.text = PVTimeHelper.convertIntToHMSString(time: currentTime)
            self.startTime = Int(currentTime)
        } else if self.endTimeInput.isFirstResponder {
            self.endTimeInput.text = PVTimeHelper.convertIntToHMSString(time: currentTime)
            self.endTime = Int(currentTime)
        }
    }
    
    @IBAction func previewClip(_ sender: Any) {
        if let startTime = self.startTime {
            self.pvMediaPlayer.seek(toTime: Double(startTime))
        }
        
        if let endTime = self.endTime {
            self.pvMediaPlayer.shouldStopAtEndTime = Int64(endTime)
        }
        
        self.pvMediaPlayer.play()
    }
    
    fileprivate func addObservers() {
        self.addObserver(self, forKeyPath: #keyPath(audioPlayer.state), options: [.new, .old], context: nil)
    }
    
    fileprivate func removeObservers() {
        self.removeObserver(self, forKeyPath: #keyPath(audioPlayer.state), context: nil)
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
    
    @IBAction func save(_ sender: Any) {
        
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
                
                self.navigationController?.popViewController(animated: true)
            }
            
            self.present(activityVC, animated: true, completion: nil)
        }))
        
        actions.addAction(UIAlertAction(title: "Done", style: .cancel, handler: { action in
            self.navigationController?.popViewController(animated: true)
        }))
        
        self.present(actions, animated: true, completion: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let keyPath = keyPath {
            if keyPath == #keyPath(audioPlayer.state) {
                self.togglePlayIcon()
                self.updateTime()
            }
        }
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
    
    private func togglePlayIcon() {
        DispatchQueue.main.async {
            if self.pvMediaPlayer.audioPlayer.state == .stopped || self.pvMediaPlayer.audioPlayer.state == .paused {
                self.activityIndicator.isHidden = true
                self.play.image = UIImage(named:"play")
                self.play.tintColor = UIColor.black
                self.play.isHidden = false
            } else if self.pvMediaPlayer.audioPlayer.state == .error {
                self.activityIndicator.isHidden = true
                self.play.image = UIImage(named:"playerror")?.withRenderingMode(.alwaysTemplate)
                self.play.tintColor = UIColor.red
                self.play.isHidden = false
            } else if self.pvMediaPlayer.audioPlayer.state == .playing && !self.pvMediaPlayer.shouldSetupClip {
                self.activityIndicator.isHidden = true
                self.play.image = UIImage(named:"pause")
                self.play.tintColor = UIColor.black
                self.play.isHidden = false
            } else if self.pvMediaPlayer.audioPlayer.state == .buffering || self.pvMediaPlayer.shouldSetupClip {
                self.activityIndicator.isHidden = false
                self.play.isHidden = true
            } else {
                self.activityIndicator.isHidden = true
                self.play.image = UIImage(named:"play")
                self.play.tintColor = UIColor.black
                self.play.isHidden = false
            }
        }
    }
    
    @objc private func updateTime () {
        DispatchQueue.main.async {
            
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
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.layer.shadowColor = UIColor.white.cgColor
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.layer.shadowColor = UIColor.clear.cgColor
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        self.endTime = nil
        
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // Prevent select / paste menu options from appearing in UITextFields
    override public func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if startTimeInput.isFirstResponder || endTimeInput.isFirstResponder {
            DispatchQueue.main.async {
                (sender as? UIMenuController)?.setMenuVisible(false, animated: false)
            }
            return false
        }
        
        return super.canPerformAction(action, withSender: sender)
    }
    
    @IBAction func sliderTapped(_ sender: Any) {
        pvMediaPlayer.playOrPause()
    }
    
    @IBAction func slidingRecognized(_ sender: Any) {
        if let pan = sender as? UIPanGestureRecognizer, let duration = pvMediaPlayer.duration {
            
            if pvMediaPlayer.checkIfNothingIsCurrentlyLoadedInPlayer() {
                let panPoint = pan.velocity(in: self.playbackControlView)
                let newTime = ((Double(self.progress.value) * duration) + Double(panPoint.x / 140.0))
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
