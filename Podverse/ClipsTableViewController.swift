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
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.isHidden = true
        activityIndicator.startAnimating()
        MediaRef.shared.delegate = self
        
        MediaRef.retrieveMediaRefsFromServer() { (mediaRefs) -> Void in
            self.reloadClipData(mediaRefs: mediaRefs)
        }

    }
    
    func reloadClipData(mediaRefs: [MediaRef]? = nil) {
        for mediaRef in mediaRefs ?? [] {
            self.clipsArray.append(mediaRef)
        }
        self.tableView.reloadData()
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

extension ClipsTableViewController:MediaRefDelegate {
    func mediaRefsRetrievedFromServer() {
        let when = DispatchTime.now() + 0.3
        DispatchQueue.main.asyncAfter(deadline: when) {
            self.loadingView.isHidden = true
            self.tableView.isHidden = false
        }
    }
}
