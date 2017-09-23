//
//  ClipsTableViewController.swift
//  Podverse
//
//  Created by Mitchell Downey on 6/6/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

import UIKit

class ClipsTableViewController: PVViewController {

    var clipsArray = [MediaRef]()
    let reachability = PVReachability.shared
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var statusMessage: UILabel!
    @IBOutlet weak var retryButton: UIButton!
    
    @IBOutlet weak var filterType: UIButton!
    @IBOutlet weak var sorting: UIButton!

    var filterTypeSelected: ClipFilterType?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        activityIndicator.hidesWhenStopped = true
        showIndicator()
        
        if let savedFilterType = UserDefaults.standard.value(forKey: kClipsTableFilterType) as? String {
            self.filterTypeSelected = ClipFilterType(rawValue: savedFilterType)
        }
        
        if self.filterTypeSelected == .subscribed {
            MediaRef.retrieveMediaRefsFromServer() { (mediaRefs) -> Void in
                self.reloadClipData(mediaRefs: mediaRefs)
            }
            filterType.setTitle("Subscribed\u{2304}", for: .normal)
        } else {
            MediaRef.retrieveMediaRefsFromServer() { (mediaRefs) -> Void in
                self.reloadClipData(mediaRefs: mediaRefs)
            }
            filterType.setTitle("All Podcasts\u{2304}", for: .normal)
        }
    }
    
    @IBAction func updateFilter(_ sender: Any) {
        let alert = UIAlertController(title: "Clips From", message: nil, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Subscribed", style: .default, handler: { action in
            MediaRef.retrieveMediaRefsFromServer(episodeMediaUrl: nil, podcastFeedUrl: nil) { (mediaRefs) -> Void in
                self.reloadClipData(mediaRefs: mediaRefs)
            }
            self.filterType.setTitle("Subscribed\u{2304}", for: .normal)
            self.filterTypeSelected = .subscribed
            UserDefaults.standard.set("Subscribed", forKey: kClipsTableFilterType)
        }))
        
        
        alert.addAction(UIAlertAction(title: "All Podcasts", style: .default, handler: { action in
            MediaRef.retrieveMediaRefsFromServer(episodeMediaUrl: nil, podcastFeedUrl: nil) { (mediaRefs) -> Void in
                self.reloadClipData(mediaRefs: mediaRefs)
            }
            self.filterType.setTitle("All Podcasts\u{2304}", for: .normal)
            self.filterTypeSelected = .allPodcasts
            UserDefaults.standard.set("All Podcasts", forKey: kClipsTableFilterType)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    
    @IBAction func updateSorting(_ sender: Any) {
        
    }
    
    @IBAction func retryButtonTouched(_ sender: Any) {
        showIndicator()
        MediaRef.retrieveMediaRefsFromServer() { (mediaRefs) -> Void in
            self.reloadClipData(mediaRefs: mediaRefs)
        }
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

extension ClipsTableViewController:UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
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
        
        if let time = clip.readableStartAndEndTime() {
            cell.time?.text = time
        }
        
        if let episodePubDate = clip.episodePubDate {
            cell.episodePubDate?.text = episodePubDate.toShortFormatString()
        }
        
        cell.podcastImage.sd_setImage(with: URL(string: clip.podcastImageUrl ?? ""), placeholderImage: #imageLiteral(resourceName: "PodverseIcon"))
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let clip = clipsArray[indexPath.row]
        let playerHistoryItem = self.playerHistoryManager.convertMediaRefToPlayerHistoryItem(mediaRef: clip)
        self.goToNowPlaying()
        self.pvMediaPlayer.loadPlayerHistoryItem(item: playerHistoryItem)
    }
    
    override func goToNowPlaying () {
        if let mediaPlayerVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MediaPlayerVC") as? MediaPlayerViewController {
            self.pvMediaPlayer.shouldAutoplayOnce = true
            self.navigationController?.pushViewController(mediaPlayerVC, animated: true)
        }
    }
    
}
