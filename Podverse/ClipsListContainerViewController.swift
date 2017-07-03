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

class ClipsListContainerViewController: UIViewController {

    @IBOutlet weak var segmentControl: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var statusMessage: UILabel!
    @IBOutlet weak var retryButton: UIButton!
    
    let pvMediaPlayer = PVMediaPlayer.shared
    var clipsArray = [MediaRef]()
    weak var delegate:ClipsListDelegate?
    let reachability = PVReachability.shared
    
    @IBAction func segmentSelect(_ sender: UISegmentedControl) {
        showIndicator()
        
        clipsArray.removeAll()
        self.tableView.reloadData()
        
        if let item = pvMediaPlayer.currentlyPlayingItem {
            switch sender.selectedSegmentIndex {
            case 0:
                MediaRef.retrieveMediaRefsFromServer(episodeMediaUrl: item.episodeMediaUrl, podcastFeedUrl: nil) { (mediaRefs) -> Void in
                    self.reloadClipData(mediaRefs: mediaRefs)
                }
            case 1:
                MediaRef.retrieveMediaRefsFromServer(episodeMediaUrl: nil, podcastFeedUrl: item.podcastFeedUrl) { (mediaRefs) -> Void in
                    self.reloadClipData(mediaRefs: mediaRefs)
                }
            case 2:
                MediaRef.retrieveMediaRefsFromServer(episodeMediaUrl: nil, podcastFeedUrl: nil) { (mediaRefs) -> Void in
                    self.reloadClipData(mediaRefs: mediaRefs)
                }
            default:
                break
            }
        }
    }
    
    @IBAction func retryButtonTouched(_ sender: Any) {
        segmentControl.sendActions(for: .valueChanged)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.separatorColor = .clear
        activityIndicator.startAnimating()
        showIndicator()
        
        if let item = pvMediaPlayer.currentlyPlayingItem {
            MediaRef.retrieveMediaRefsFromServer(episodeMediaUrl: item.episodeMediaUrl, podcastFeedUrl: nil) { (mediaRefs) -> Void in
                self.reloadClipData(mediaRefs: mediaRefs)
            }
        }
    }
    
    func reloadClipData(mediaRefs: [MediaRef]? = nil) {
        let when = DispatchTime.now() + 0.3
        DispatchQueue.main.asyncAfter(deadline: when) {
            if mediaRefs?.count == 0 && self.reachability.hasInternetConnection() == false {
                self.showStatusMessage(message: "You must connect to the internet to load clips.")
                return
            }
            
            if mediaRefs?.count == 0 {
                self.showStatusMessage(message: "No clips available")
                return
            }
            
            if let mediaRefs = mediaRefs {
                for mediaRef in mediaRefs {
                    self.clipsArray.append(mediaRef)
                }
            }
            
            self.showClipsView()
            
            self.tableView.reloadData()
        }
    }
    
    func showStatusMessage(message: String) {
        statusMessage.text = message
        tableView.isHidden = true
        loadingView.isHidden = false
        activityIndicator.isHidden = true
        statusMessage.isHidden = false
        
        if message == "You must connect to the internet to load clips." {
            retryButton.isHidden = false
        }
    }
    
    func showIndicator() {
        tableView.isHidden = true
        loadingView.isHidden = false
        activityIndicator.isHidden = false
        statusMessage.isHidden = true
        retryButton.isHidden = true
    }
    
    func showClipsView() {
        tableView.isHidden = false
        loadingView.isHidden = true
        activityIndicator.isHidden = true
        statusMessage.isHidden = true
        retryButton.isHidden = true
    }
}

extension ClipsListContainerViewController:UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return clipsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "mediaPlayerClipCell", for:indexPath) as! MediaPlayerClipTableViewCell
        let clip = clipsArray[indexPath.row]
        
        if let title = clip.title {
            cell.clipTitle.text = title
        }
        
        if let startTime = clip.startTime {
            cell.startTime.text = startTime.toMediaPlayerString()
        }
        
        if let endTime = clip.endTime {
            cell.endTime.text = endTime.toMediaPlayerString()
        }
        
        return cell

    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.delegate?.didSelectClip(clip: self.clipsArray[indexPath.row])
    }
}

