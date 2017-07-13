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

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var retryButton: UIButton!
    @IBOutlet weak var statusMessage: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var filterType: UIButton!
    @IBOutlet weak var sorting: UIButton!
    
    let pvMediaPlayer = PVMediaPlayer.shared
    var clipsArray = [MediaRef]()
    weak var delegate:ClipsListDelegate?
    let reachability = PVReachability.shared
        
    @IBAction func retryButtonTouched(_ sender: Any) {
        
    }
    @IBAction func updateFilter(_ sender: Any) {
        let alert = UIAlertController(title: "Clips From", message: nil, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Episode", style: .default, handler: { action in
            if let item = self.pvMediaPlayer.currentlyPlayingItem {
                MediaRef.retrieveMediaRefsFromServer(episodeMediaUrl: item.episodeMediaUrl, podcastFeedUrl: nil) { (mediaRefs) -> Void in
                    self.reloadClipData(mediaRefs: mediaRefs)
                }
            }
            self.filterType.setTitle("Episode\u{2304}", for: .normal)
        }))
        
        alert.addAction(UIAlertAction(title: "Podcast", style: .default, handler: { action in
            if let item = self.pvMediaPlayer.currentlyPlayingItem {
                MediaRef.retrieveMediaRefsFromServer(episodeMediaUrl: nil, podcastFeedUrl: item.podcastFeedUrl) { (mediaRefs) -> Void in
                    self.reloadClipData(mediaRefs: mediaRefs)
                }
            }
            self.filterType.setTitle("Podcast\u{2304}", for: .normal)
        }))
        
        alert.addAction(UIAlertAction(title: "Subscribed", style: .default, handler: { action in
            if let _ = self.pvMediaPlayer.currentlyPlayingItem {
                MediaRef.retrieveMediaRefsFromServer(episodeMediaUrl: nil, podcastFeedUrl: nil) { (mediaRefs) -> Void in
                    self.reloadClipData(mediaRefs: mediaRefs)
                }
            }
            self.filterType.setTitle("Subscribed\u{2304}", for: .normal)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.separatorColor = .clear
        activityIndicator.hidesWhenStopped = true
        showIndicator()
        
        if let item = pvMediaPlayer.currentlyPlayingItem {
            MediaRef.retrieveMediaRefsFromServer(episodeMediaUrl: item.episodeMediaUrl, podcastFeedUrl: nil) { (mediaRefs) -> Void in
                self.reloadClipData(mediaRefs: mediaRefs)
            }
        }
        
        filterType.setTitle("Episode\u{2304}", for: .normal)
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

