//
//  ClipsListContainerViewController.swift
//  Podverse
//
//  Created by Creon Creonopoulos on 5/30/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

import UIKit

protocol ClipsListDelegate:class {
    func didSelectClip(clip:MediaRef)
}

enum ClipFilterType {
    case episode, podcast, subscribed
    
    var text:String {
        get {
            switch self {
            case .episode:
                return "Episode"
            case .podcast:
                return "Podcast"
            case .subscribed:
                return "Subscribed"
            }
        }
    }
}

class ClipsListContainerViewController: UIViewController {

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var filterType: UIButton!
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var retryButton: UIButton!
    @IBOutlet weak var sorting: UIButton!
    @IBOutlet weak var statusMessage: UILabel!
    @IBOutlet weak var tableControlsView: UIView!
    @IBOutlet weak var tableView: UITableView!
    
    let pvMediaPlayer = PVMediaPlayer.shared
    var clipsArray = [MediaRef]()
    weak var delegate:ClipsListDelegate?
    let reachability = PVReachability.shared
    
    var filterTypeSelected:ClipFilterType = .subscribed
    
    @IBAction func retryButtonTouched(_ sender: Any) {
        
    }
    
    @IBAction func updateFilter(_ sender: Any) {
        let alert = UIAlertController(title: "Clips From", message: nil, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Episode", style: .default, handler: { action in
            if let item = self.pvMediaPlayer.nowPlayingItem {
                MediaRef.retrieveMediaRefsFromServer(episodeMediaUrl: item.episodeMediaUrl, podcastFeedUrl: nil) { (mediaRefs) -> Void in
                    self.reloadClipData(mediaRefs: mediaRefs)
                }
            }
            self.filterType.setTitle("Episode\u{2304}", for: .normal)
            self.filterTypeSelected = .episode
        }))
        
        alert.addAction(UIAlertAction(title: "Podcast", style: .default, handler: { action in
            if let item = self.pvMediaPlayer.nowPlayingItem {
                MediaRef.retrieveMediaRefsFromServer(episodeMediaUrl: nil, podcastFeedUrl: item.podcastFeedUrl) { (mediaRefs) -> Void in
                    self.reloadClipData(mediaRefs: mediaRefs)
                }
            }
            self.filterType.setTitle("Podcast\u{2304}", for: .normal)
            self.filterTypeSelected = .podcast
        }))
        
        alert.addAction(UIAlertAction(title: "Subscribed", style: .default, handler: { action in
            if let _ = self.pvMediaPlayer.nowPlayingItem {
                MediaRef.retrieveMediaRefsFromServer(episodeMediaUrl: nil, podcastFeedUrl: nil) { (mediaRefs) -> Void in
                    self.reloadClipData(mediaRefs: mediaRefs)
                }
            }
            self.filterType.setTitle("Subscribed\u{2304}", for: .normal)
            self.filterTypeSelected = .subscribed
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.separatorColor = .darkGray
        self.tableControlsView.layer.borderColor = UIColor.lightGray.cgColor
        self.tableControlsView.layer.borderWidth = 1.0
        
        activityIndicator.hidesWhenStopped = true
        showIndicator()
        
        tableView.rowHeight = UITableViewAutomaticDimension
        
        if let item = pvMediaPlayer.nowPlayingItem {
            MediaRef.retrieveMediaRefsFromServer(episodeMediaUrl: item.episodeMediaUrl, podcastFeedUrl: nil) { (mediaRefs) -> Void in
                self.reloadClipData(mediaRefs: mediaRefs)
            }
        }
        
        filterType.setTitle("Subscribed\u{2304}", for: .normal)
    }
    
    func reloadClipData(mediaRefs: [MediaRef]? = nil) {
        if self.reachability.hasInternetConnection() == false {
            self.showStatusMessage(message: "You must connect to the internet to load clips.")
            return
        }
        
        guard let mediaRefArray = mediaRefs, mediaRefArray.count > 0 else {
            self.showStatusMessage(message: "No clips available")
            return
        }
        
        for mediaRef in mediaRefArray {
            self.clipsArray.append(mediaRef)
        }
        
        self.showClipsView()
        self.tableView.reloadData()
    }
    
    func showStatusMessage(message: String) {
        activityIndicator.stopAnimating()
        statusMessage.text = message
        tableView.isHidden = true
        loadingView.isHidden = false
        statusMessage.isHidden = false
        
        if message == "You must connect to the internet to load clips." {
            retryButton.isHidden = false
        }
    }
    
    func showIndicator() {
        activityIndicator.startAnimating()
        tableView.isHidden = true
        loadingView.isHidden = false
        activityIndicator.isHidden = false
        statusMessage.isHidden = true
        retryButton.isHidden = true
    }
    
    func showClipsView() {
        activityIndicator.stopAnimating()
        tableView.isHidden = false
        loadingView.isHidden = true
        statusMessage.isHidden = true
        retryButton.isHidden = true
    }
    
}

extension ClipsListContainerViewController:UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return clipsArray.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        //if filterTypeSelected == .episode {
            
        //} else if filterTypeSelected == .podcast {
            
        //} else {
            
        //}
        
        let clip = clipsArray[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ClipTableViewCell
        
        cell.podcastTitle?.text = clip.podcastTitle
        cell.episodeTitle?.text = clip.episodeTitle
        cell.clipTitle?.text = clip.title
        
        var time: String?
        
        if let startTime = clip.startTime {
            if let endTime = clip.endTime {
                if endTime > 0 {
                    time = startTime.toMediaPlayerString() + " to " + endTime.toMediaPlayerString()
                }
            } else {
                time = "Starts:" + startTime.toMediaPlayerString()
            }
        }
        
        if let time = time {
            cell.time?.text = time
        }
        
        if let episodePubDate = clip.episodePubDate {
            cell.episodePubDate?.text = episodePubDate.toShortFormatString()
        }
        
        Podcast.retrievePodcastImage(podcastImageURLString: clip.podcastImageUrl) { (podcastImage) -> Void in
            if let visibleRows = self.tableView.indexPathsForVisibleRows, visibleRows.contains(indexPath), let existingCell = self.tableView.cellForRow(at: indexPath) as? ClipTableViewCell, let podcastImage = podcastImage {
                    existingCell.podcastImage?.image = podcastImage
            }
        }
        
        
        return cell

    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.delegate?.didSelectClip(clip: self.clipsArray[indexPath.row])
    }
}

