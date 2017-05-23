//
//  MediaPlayerViewController.swift
//  Podverse
//
//  Created by Mitchell Downey on 5/17/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

import UIKit
import CoreData
import AVFoundation

class MediaPlayerViewController: PVViewController {
    
    let pvMediaPlayer = PVMediaPlayer.shared
    
    @IBOutlet weak var playPauseButton: UIButton!
    
    @IBAction func playPause(_ sender: Any) {
        // Call playOrPause function, which returns a boolean for isNowPlaying status
        let isNowPlaying = pvMediaPlayer.playOrPause()

        if isNowPlaying == true {
            // Change Play/Pause button to Play icon
            playPauseButton.setTitle("\u{f04c}", for: .normal)
        } else {
            // Change Play/Pause button to Pause icon
            playPauseButton.setTitle("\u{f04b}", for: .normal)
        }
    }
    
    func setPlayPauseIcon() {
        // Check if a clip or episode is loaded. If it is, then display either Play or Pause icon.
        if pvMediaPlayer.avPlayer.rate == 1 {
            // If playing, then display Play icon.
            playPauseButton.setTitle("\u{f04c}", for: .normal)
        } else {
            // If paused, then display Pause icon.
            playPauseButton.setTitle("\u{f04b}", for: .normal)
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Make sure the Play/Pause button displays properly after returning from background
        NotificationCenter.default.addObserver(self, selector: #selector(MediaPlayerViewController.setPlayPauseIcon), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        
        setPlayPauseIcon()
        
    }

    
// class MediaPlayerViewController: PVViewController, PVMediaPlayerDelegate {
    
//    let makeClipString = "Make Clip"
//    let hideClipper = "Hide Clipper"
//    let buttonMakeClip = UIButton(type : UIButtonType.Custom)
//    var clipper:PVClipperViewController?
//    
//    let addToList = "Add to List"
//    let buttonAddToList = UIButton(type: UIButtonType.Custom)
//
//    let reachability = PVReachability.manager
//    
//    let managedObjectContext = CoreDataHelper.sharedInstance.managedObjectContext
//    
//    var nowPlayingCurrentTimeTimer: NSTimer!
//    var playerSpeedRate:PlayingSpeed = .Regular
//    
//    @IBOutlet weak var mediaPlayerImage: UIImageView!
//    @IBOutlet weak var podcastTitle: UILabel!
//    @IBOutlet weak var episodeTitle: UILabel!
//    @IBOutlet weak var episodePubDate: UILabel!
//    @IBOutlet weak var currentTime: UILabel!
//    @IBOutlet weak var totalTime: UILabel!
//    @IBOutlet weak var summary: UITextView!
//
//    @IBOutlet weak var skipButton: UIButton!
//    @IBOutlet weak var previousButton: UIButton!
//    @IBOutlet weak var speedButton: UIButton!
//    @IBOutlet weak var audioButton: UIButton!
//    
//    @IBOutlet weak var nowPlayingSlider: UISlider!
//    
//    @IBOutlet weak var makeClipContainerView: UIView!
//    
//    @IBOutlet weak var speedLabel: UILabel!
//    
//    @IBOutlet weak var profileHeader: UIView!
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
//        
//        // If no nowPlaying episode or clip exists, then nav back out of MediaPlayerVC
//        if pvMediaPlayer.nowPlayingEpisode == nil && pvMediaPlayer.nowPlayingClip == nil {
//            self.navigationController?.popViewControllerAnimated(true)
//        }
//        
//        pvMediaPlayer.delegate = self
//        
//        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(MediaPlayerViewController.dismissKeyboard)))
//        guard let navVC = self.childViewControllers.first as? UINavigationController else {
//            return
//        }
//        
//        self.clipper = (navVC.topViewController as? PVClipperViewController)
//        
//        if let duration = pvMediaPlayer.nowPlayingEpisode.duration {
//            self.clipper?.totalDuration = Int(duration)
//        }
//        
//        buttonMakeClip.frame = CGRectMake(0, 0, 100, 90)
//        buttonMakeClip.setTitle(makeClipString, forState: .Normal)
//        buttonMakeClip.titleLabel!.font = UIFont(name: "System", size: 18)
//        buttonMakeClip.addTarget(self, action: #selector(MediaPlayerViewController.toggleMakeClipView(_:)), forControlEvents: .TouchUpInside)
//        let rightBarButtonMakeClip: UIBarButtonItem = UIBarButtonItem(customView: buttonMakeClip)
//        
//        makeClipContainerView.hidden = true
//        
//        buttonAddToList.frame = CGRectMake(0, 0, 100, 90)
//        buttonAddToList.setTitle(addToList, forState: .Normal)
//        buttonAddToList.titleLabel!.font = UIFont(name: "System", size: 18)
//        buttonAddToList.addTarget(self, action: #selector(MediaPlayerViewController.addNowPlayingToList), forControlEvents: .TouchUpInside)
//        let rightBarButtonAddToList: UIBarButtonItem = UIBarButtonItem(customView: buttonAddToList)
//        
//        var rightBarButtonArray = [UIBarButtonItem]()
//        
//        rightBarButtonArray.append(rightBarButtonAddToList)
//        
//        if pvMediaPlayer.nowPlayingClip == nil {
//            rightBarButtonArray.append(rightBarButtonMakeClip)
//        }
//        
//        self.navigationItem.setRightBarButtonItems(rightBarButtonArray, animated: false)
//        
//        // Populate the Media Player UI with the current episode's information
//        if let imageData = pvMediaPlayer.nowPlayingEpisode.podcast.imageThumbData {
//            mediaPlayerImage.image = UIImage(data: imageData)
//        }
//        
//        podcastTitle?.text = pvMediaPlayer.nowPlayingEpisode.podcast.title
//        episodeTitle?.text = pvMediaPlayer.nowPlayingEpisode.title
//        
//        if let pubDate = pvMediaPlayer.nowPlayingEpisode.pubDate {
//            episodePubDate?.text = PVUtility.formatDateToString(pubDate)
//        }
//        
//        if let nowPlayingClip = pvMediaPlayer.nowPlayingClip {
//            totalTime?.text = PVUtility.convertNSNumberToHHMMSSString(nowPlayingClip.duration)
//        }
//        else {
//            totalTime?.text = PVUtility.convertNSNumberToHHMMSSString(pvMediaPlayer.nowPlayingEpisode.duration)
//            correctEpisodeDuration()
//        }
//        
//        var summaryString = ""
//        if let clip = pvMediaPlayer.nowPlayingClip {
//            
//            summaryString += "Start: " + PVUtility.convertNSNumberToHHMMSSString(clip.startTime)
//            
//            if let endTime = clip.endTime {
//                summaryString += " – End: " + PVUtility.convertNSNumberToHHMMSSString(endTime)
//            }
//            
//            summaryString += "\n\n"
//            
//            if let clipDescription = clip.pvDescription {
//                summaryString += clipDescription + "\n\n"
//            }
//            
//            summaryString += "--- \n\n"
//        }
//        
//        if let episodeSummary = pvMediaPlayer.nowPlayingEpisode.summary, let cleanedEpisodeSummary = PVUtility.removeHTMLFromString(episodeSummary) {
//            summaryString += cleanedEpisodeSummary
//        }
//        
//        summary?.text = summaryString
//        
//        let gesture = UITapGestureRecognizer(target: self, action: #selector(showPodcastProfile))
//        profileHeader.addGestureRecognizer(gesture)
//
//        updateSpeedLabel()
//        
//        pvMediaPlayer.avPlayer.addPeriodicTimeObserverForInterval(CMTimeMake(1, 1), queue: dispatch_get_main_queue()) { (currentTime) in
//            self.updateCurrentTime(CMTimeGetSeconds(currentTime))
//        }
//    }
//    
//    var viewDidLayoutSubviewsAtLeastOnce = false
//    
//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//        
//        if !viewDidLayoutSubviewsAtLeastOnce {
//            summary?.setContentOffset(CGPointZero, animated: false)
//        }
//        
//        viewDidLayoutSubviewsAtLeastOnce = true
//    }
//    
//    func showPodcastProfile() {
//        
//        let searchResultPodcastActions = UIAlertController(title: "Podcast Options", message: "", preferredStyle: UIAlertControllerStyle.ActionSheet)
//        
//        
//        searchResultPodcastActions.addAction(UIAlertAction(title: "Subscribe", style: .Default, handler: { action in
//            print("Subscribe")
//        }))
//        
//        // TODO: add follow feature
//        searchResultPodcastActions.addAction(UIAlertAction(title: "Follow", style: .Default, handler: { action in
//            print("Follow")
//        }))
//        
//        searchResultPodcastActions.addAction(UIAlertAction (title: "Profile", style: .Default, handler: { action in
//            self.performSegueWithIdentifier("Show Podcast Profile", sender: nil)
//        }))
//        
//        searchResultPodcastActions.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
//        
//        self.presentViewController(searchResultPodcastActions, animated: false, completion: nil)
//    }
//    
//    private func updateSpeedLabel() {
//        self.speedLabel.text = playerSpeedRate.speedText
//    }
//    
//    func dismissKeyboard (){
//        self.view.endEditing(true)
//    }
//    
//    func correctEpisodeDuration () {
//        guard let mediaURLstring = pvMediaPlayer.nowPlayingEpisode.mediaURL else {
//            return
//        }
//        
//        guard let mediaURL = NSURL(string: mediaURLstring) else {
//            return
//        }
//        
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
//            let calculateDurationAsset = AVURLAsset(URL: mediaURL, options: nil)
//            
//            var calculatedDuration = CMTimeGetSeconds(calculateDurationAsset.duration)
//            calculatedDuration = floor(calculatedDuration)
//            
//            dispatch_async(dispatch_get_main_queue(), {
//                if self.pvMediaPlayer.nowPlayingEpisode != nil {
//                    self.totalTime?.text = PVUtility.convertNSNumberToHHMMSSString(NSNumber(double: calculatedDuration))
//                    self.clipper?.totalDuration = Int(calculatedDuration)
//                    self.pvMediaPlayer.nowPlayingEpisode.duration = NSNumber(double: calculatedDuration)
//                }
//            })
//        })
//    }
//    
//    @IBAction func sliderTimeChange(sender: UISlider) {
//        let currentSliderValue = Float64(sender.value)
//        var totalTime: Float64 = 0.0
//        
//        if let clip = pvMediaPlayer.nowPlayingClip, let duration = clip.duration {
//            totalTime = Float64(duration)
//        } else {
//            if pvMediaPlayer.nowPlayingEpisode != nil {
//                if let duration = pvMediaPlayer.nowPlayingEpisode.duration {
//                    totalTime = Float64(duration)
//                }
//            }
//        }
//        
//        let resultTime = totalTime * currentSliderValue
//        pvMediaPlayer.goToTime(resultTime)
//    }
//
//    @IBAction func skip(sender: AnyObject) {
//    }
//    
//    @IBAction func previous(sender: AnyObject) {
//    }
//    
//    @IBAction func speed(sender: AnyObject) {
//        switch playerSpeedRate {
//        case .Regular:
//            playerSpeedRate = .TimeAndQuarter
//            break
//        case .TimeAndQuarter:
//            playerSpeedRate = .TimeAndHalf
//            break
//        case .TimeAndHalf:
//            playerSpeedRate = .Double
//            break
//        case .Double:
//            playerSpeedRate = .DoubleAndHalf
//            break
//        case .DoubleAndHalf:
//            playerSpeedRate = .Quarter
//            break
//        case .Quarter:
//            playerSpeedRate = .Half
//            break
//        case .Half:
//            playerSpeedRate = .ThreeQuarts
//            break
//        case .ThreeQuarts:
//            playerSpeedRate = .Regular
//            break
//        }
//        
//        pvMediaPlayer.avPlayer.rate = playerSpeedRate.speedVaue
//        updateSpeedLabel()
//    }
//    
//    @IBAction func audio(sender: AnyObject) {
//    }
//    
//    @IBAction func skip1minute(sender: AnyObject) {
//        pvMediaPlayer.skipTime(60)
//    }
//    
//    @IBAction func skip15seconds(sender: AnyObject) {
//        pvMediaPlayer.skipTime(15)
//    }
//    
//    @IBAction func previous15seconds(sender: AnyObject) {
//        pvMediaPlayer.previousTime(15)
//    }
//    
//    @IBAction func previous1minute(sender: AnyObject) {
//        pvMediaPlayer.previousTime(60)
//    }
//    
//    override func viewWillAppear(animated: Bool) {
//        super.viewWillAppear(animated)
//        
//        self.navigationController?.navigationBar.barTintColor = UIColor(red: 0.0/255.0, green: 0.0/255.0, blue: 0.0/255.0, alpha: 1.0)
//        
//        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
//        self.navigationController?.navigationBar.shadowImage = UIImage()
//        
//        // If loading the MediaPlayerVC when with no currentItem in the avPlayer, then nav back a page. Else load the MediaPlayerVC with the current item and related info.
//        if pvMediaPlayer.avPlayer.currentItem == nil {
//            self.navigationController?.popViewControllerAnimated(true)
//        } else {
//            // If currentTime != 0.0, then immediately insert the currentTime in its label; else manually set the currentTime label to 00:00.
//            if CMTimeGetSeconds(pvMediaPlayer.avPlayer.currentTime()) != 0.0 {
//                updateCurrentTime(CMTimeGetSeconds(pvMediaPlayer.avPlayer.currentTime()))
//            } else {
//                currentTime?.text = "00:00"
//            }
//            
//            setPlayPauseIcon()
//        }
//    }
//    
//    override func didReceiveMemoryWarning() {
//        super.didReceiveMemoryWarning()
//        // Dispose of any resources that can be recreated.
//    }
//    
//    override func viewWillDisappear(animated: Bool) {
//        super.viewWillDisappear(animated)
//        
//        // Stop timer that checks every second if the now playing current time has changed
//        if nowPlayingCurrentTimeTimer != nil {
//            nowPlayingCurrentTimeTimer.invalidate()
//        }
//        
//        if (self.isMovingFromParentViewController()){
//            self.navigationController?.navigationBar.barTintColor = UIColor(red: 41.0/255.0, green: 104.0/255.0, blue: 177.0/255.0, alpha: 1.0)
//        }
//    }
//    
//    func toggleMakeClipView(sender: UIButton!) {
//        if !reachability.hasInternetConnection() && makeClipContainerView.hidden {
//            showInternetNeededAlert("Connect to WiFi or cellular data to make a clip.")
//            return
//        }
//        makeClipContainerView.hidden = !makeClipContainerView.hidden
//        
//        if makeClipContainerView.hidden == true {
//            self.view.endEditing(true)
//            buttonMakeClip.setTitle(makeClipString, forState: .Normal)
//            for viewController in self.childViewControllers {
//                if viewController.isKindOfClass(UINavigationController) {
//                    (viewController as! UINavigationController).popToRootViewControllerAnimated(false)
//                }
//            }
//        }
//        else {
//            if let PVClipper = self.clipper {
//                PVClipper.startTime = Int(CMTimeGetSeconds(pvMediaPlayer.avPlayer.currentTime()))
//                PVClipper.endTime = Int(CMTimeGetSeconds(pvMediaPlayer.avPlayer.currentTime())) + 60
//                PVClipper.updateUI()
//                PVClipper.currentEpisode = pvMediaPlayer.nowPlayingEpisode
//                PVClipper.navToInitialTextField()
//            }
//            buttonMakeClip.setTitle(hideClipper, forState: .Normal)
//        }
//    }
//    
//    func addNowPlayingToList() {
//        if !reachability.hasInternetConnection() {
//            showInternetNeededAlert("Connect to WiFi or cellular data to add to a playlist.")
//            return
//        }
//        self.performSegueWithIdentifier("Add to Playlist", sender: nil)
//    }
//    
//    func setMediaPlayerVCPlayPauseIcon() {
//        setPlayPauseIcon()
//    }
//    
//    func episodeFinishedPlaying(currentEpisode: Episode) {
//        NSNotificationCenter.defaultCenter().removeObserver(self, name: Constants.kNowPlayingTimeHasChanged, object: nil)
//        pvMediaPlayer.clearPlayingInfo()
//        pvMediaPlayer.nowPlayingEpisode = nil
//        pvMediaPlayer.nowPlayingClip = nil
//        NSUserDefaults.standardUserDefaults().removeObjectForKey(Constants.kLastPlayingEpisodeURL)
//        
//        PVDeleter.deleteEpisode(currentEpisode.objectID)
//        
//        dispatch_async(dispatch_get_main_queue(), { () -> Void in
//            NSNotificationCenter.defaultCenter().postNotificationName(Constants.kPlayerHasNoItem, object: nil)
//            self.navigationController?.popViewControllerAnimated(true)
//        })
//    }
//    
//    func clipFinishedPlaying(currentClip: Clip) {
//        NSNotificationCenter.defaultCenter().removeObserver(self, name: Constants.kNowPlayingTimeHasChanged, object: nil)
//        pvMediaPlayer.clearPlayingInfo()
//        pvMediaPlayer.nowPlayingEpisode = nil
//        pvMediaPlayer.nowPlayingClip = nil
//        
//        dispatch_async(dispatch_get_main_queue(), { () -> Void in
//            NSNotificationCenter.defaultCenter().postNotificationName(Constants.kPlayerHasNoItem, object: nil)
//            self.navigationController?.popViewControllerAnimated(true)
//        })
//    }
//    
//    func updateCurrentTime(currentTime: Double) {
//        self.currentTime?.text = PVUtility.convertNSNumberToHHMMSSString(currentTime)
//        
//        var totalTime:Double? = 0.0
//        
//        if let clip = pvMediaPlayer.nowPlayingClip, let duration = clip.duration {
//            totalTime = duration.doubleValue
//        } else if let episode = pvMediaPlayer.nowPlayingEpisode {
//            totalTime = episode.duration?.doubleValue
//        } else {
//            dispatch_async(dispatch_get_main_queue(), { () -> Void in
//                self.navigationController?.popViewControllerAnimated(true)
//            })
//        }
//        
//        nowPlayingSlider.value = Float(currentTime / (totalTime ?? 1))
//    }
//    
//    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
//        if segue.identifier == "Show Podcast Profile" {
//            let podcastProfileViewController = segue.destinationViewController as! PodcastProfileViewController
//            podcastProfileViewController.podcast = pvMediaPlayer.nowPlayingEpisode.podcast
//        }
//    }
    
}
