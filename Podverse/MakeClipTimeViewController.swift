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
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var currentTime: UILabel!
    @IBOutlet weak var duration: UILabel!
    @IBOutlet weak var endPreview: UIButton!
    @IBOutlet weak var endTimeInput: UITextField!
    @IBOutlet weak var play: UIButton!
    @IBOutlet weak var playbackControlView: UIView!
    @IBOutlet weak var progress: UISlider!
    @IBOutlet weak var setTime: UIButton!
    @IBOutlet weak var startPreview: UIButton!
    @IBOutlet weak var startTimeInput: UITextField!
    
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
    
    @IBAction func play(_ sender: Any) {
        pvMediaPlayer.playOrPause()
    }
    
    @IBAction func timeJumpBackward(_ sender: Any) {
        let newTime = audioPlayer.progress - 15
        
        if newTime >= 14 {
            self.pvMediaPlayer.seek(toTime: newTime)
        } else {
            self.pvMediaPlayer.seek(toTime: 0)
        }
        
        updateTime()
    }
    
    @IBAction func timeJumpForward(_ sender: Any) {
        let newTime = audioPlayer.progress + 15
        self.pvMediaPlayer.seek(toTime: newTime)
        updateTime()
    }
    
    @IBAction func setTimeTouched(_ sender: Any) {
        let currentTime = Int(self.audioPlayer.progress)
        
        if self.startTimeInput.isFirstResponder {
            self.startTimeInput.text = PVTimeHelper.convertIntToHMSString(time: currentTime)
            self.startTime = Int(currentTime)
        } else if self.endTimeInput.isFirstResponder {
            self.endTimeInput.text = PVTimeHelper.convertIntToHMSString(time: currentTime)
            self.endTime = Int(currentTime)
        }
    }
    
    @IBAction func nextButtonTouched(_ sender: Any) {
        
        guard let startTime = self.startTime else {
            let alertController = UIAlertController(title: "Invalid Clip Time", message: "Start time must be provided.", preferredStyle: .alert)
            let action = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(action)
            self.present(alertController, animated: true, completion: nil)
            return
        }
        
        if let endTime = self.endTime {
            
            var alertMessage: String?
            
            // TODO: what's cleaner logic here?
            if startTime == endTime {
                alertMessage = "Start time is equal to end time."
            } else {
                alertMessage = "Start time is later than end time."
            }
            
            if startTime == endTime || startTime >= endTime {
                let alertController = UIAlertController(title: "Invalid Clip Time", message: alertMessage, preferredStyle: .alert)
                let action = UIAlertAction(title: "OK", style: .default, handler: nil)
                alertController.addAction(action)
                self.present(alertController, animated: true, completion: nil)
                return
            }
            
        }
        
        self.performSegue(withIdentifier: "Show Make Clip Title", sender: nil)
    }
    
    fileprivate func addObservers() {
        self.addObserver(self, forKeyPath: #keyPath(audioPlayer.state), options: [.new, .old], context: nil)
    }
    
    fileprivate func removeObservers() {
        self.removeObserver(self, forKeyPath: #keyPath(audioPlayer.state), context: nil)
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
            if self.audioPlayer.state == STKAudioPlayerState.buffering {
                self.activityIndicator.isHidden = false
                self.play.isHidden = true
            } else if self.audioPlayer.state == STKAudioPlayerState.playing {
                self.activityIndicator.isHidden = true
                self.play.setImage(UIImage(named:"Pause"), for: .normal)
                self.play.isHidden = false
            } else {
                self.activityIndicator.isHidden = true
                self.play.setImage(UIImage(named:"Play"), for: .normal)
                self.play.isHidden = false
            }
        }
    }
    
    @objc private func updateTime () {
        DispatchQueue.main.async {
            let playbackPosition = self.audioPlayer.progress
            self.currentTime.text = Int64(playbackPosition).toMediaPlayerString()

            if let dur = self.pvMediaPlayer.duration {
                self.duration.text = Int64(dur).toMediaPlayerString()
                self.progress.value = Float(playbackPosition / dur)
            }
            
            if let endTimePreview = self.endTimePreview {
                if Int(self.audioPlayer.progress) >= endTimePreview {
                    self.pvMediaPlayer.pause()
                    self.endTimePreview = nil
                }
            }
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.backgroundColor = UIColor.yellow
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.backgroundColor = UIColor.white
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
    
    override func viewWillAppear(_ animated: Bool) {
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
        
        updateTime()
        
        populatePlayerInfo()
        
        // prevent keyboard from displaying for startTimeInput and endTimeInput
        self.startTimeInput.inputView = UIView()
        self.endTimeInput.inputView = UIView()
        
        self.startTimeInput.text = PVTimeHelper.convertIntToHMSString(time: self.startTime)
        
        self.endTimeInput.becomeFirstResponder()
        
    }
    
    deinit {
        removeObservers()
        removeTimer()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "Show Make Clip Title" {
            
            if let playerHistoryItem = playerHistoryItem, let makeClipTitleViewController = segue.destination as? MakeClipTitleViewController {
                makeClipTitleViewController.playerHistoryItem = playerHistoryItem
                makeClipTitleViewController.startTime = self.startTime
                makeClipTitleViewController.endTime = self.endTime
            }
            
        }
        
    }
    
}
