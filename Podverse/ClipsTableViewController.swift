//
//  ClipsTableViewController.swift
//  Podverse
//
//  Created by Mitchell Downey on 6/6/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

import UIKit

class ClipsTableViewController: UIViewController {

    var clipsArray = [MediaRef]()
    let reachability = PVReachability.shared
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var statusMessage: UILabel!
    @IBOutlet weak var retryButton: UIButton!

    @IBAction func retryButtonTouched(_ sender: Any) {
        showIndicator()
        MediaRef.retrieveMediaRefsFromServer() { (mediaRefs) -> Void in
            self.reloadClipData(mediaRefs: mediaRefs)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        activityIndicator.startAnimating()
        showIndicator()
        
        MediaRef.retrieveMediaRefsFromServer() { (mediaRefs) -> Void in
            self.reloadClipData(mediaRefs: mediaRefs)
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

extension ClipsTableViewController:UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return clipsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let clip = clipsArray[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "clipCell", for: indexPath) as! ClipTableViewCell
        
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
        
        DispatchQueue.global().async {
            var cellImage:UIImage?
            // TODO: remotely retrieve cell image, if it isn't saved with a podcast locally
            cellImage = UIImage(named: "PodverseIcon")

            DispatchQueue.main.async {
                if let visibleRows = self.tableView.indexPathsForVisibleRows, visibleRows.contains(indexPath) {
                    let existingCell = self.tableView.cellForRow(at: indexPath) as! ClipTableViewCell
                    existingCell.podcastImage.image = cellImage
                }
            }
        }
        
        return cell
    }
    
}
