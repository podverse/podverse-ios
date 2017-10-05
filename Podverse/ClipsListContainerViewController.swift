//
//  ClipsListContainerViewController.swift
//  Podverse
//
//  Created by Creon Creonopoulos on 5/30/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

import UIKit
import SDWebImage

protocol ClipsListDelegate:class {
    func didSelectClip(clip:MediaRef)
}

class ClipsListContainerViewController: UIViewController {

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var filterType: UIButton!
    @IBOutlet weak var sorting: UIButton!
    @IBOutlet weak var tableControlsView: UIView!
    @IBOutlet weak var tableView: UITableView!
    
    let pvMediaPlayer = PVMediaPlayer.shared
    var clipsArray = [MediaRef]()
    weak var delegate:ClipsListDelegate?
    let reachability = PVReachability.shared
    
    var filterTypeSelected: ClipFilter = .episode {
        didSet {
            self.filterType.setTitle(filterTypeSelected.text + "\u{2304}", for: .normal)
            UserDefaults.standard.set(filterTypeSelected.text, forKey: kClipsListFilterType)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.separatorColor = .darkGray
        self.tableControlsView.layer.borderColor = UIColor.lightGray.cgColor
        self.tableControlsView.layer.borderWidth = 1.0
        
        activityIndicator.hidesWhenStopped = true
        showIndicator()
        
        if let savedFilterType = UserDefaults.standard.value(forKey: kClipsListFilterType) as? String, let sFilterType = ClipFilter(rawValue: savedFilterType) {
            self.filterTypeSelected = sFilterType
        }
        
        retrieveClipData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkForConnectvity()
    }
    
    @IBAction func retryButtonTouched(_ sender: Any) {
        
    }
    
    @IBAction func updateFilter(_ sender: Any) {
        let alert = UIAlertController(title: "Clips From", message: nil, preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "Episode", style: .default, handler: { action in
            if let item = self.pvMediaPlayer.nowPlayingItem {
                MediaRef.retrieveMediaRefsFromServer(episodeMediaUrl: item.episodeMediaUrl, podcastFeedUrls: []) { (mediaRefs) -> Void in
                    self.reloadClipData(mediaRefs: mediaRefs)
                }
            }
            self.filterType.setTitle("Episode\u{2304}", for: .normal)
            self.filterTypeSelected = .episode
            UserDefaults.standard.set("Episode", forKey: kClipsListFilterType)
        }))
        
        alert.addAction(UIAlertAction(title: "Podcast", style: .default, handler: { action in
            if let item = self.pvMediaPlayer.nowPlayingItem, let podcastFeedUrl = item.podcastFeedUrl {
                MediaRef.retrieveMediaRefsFromServer(episodeMediaUrl: nil, podcastFeedUrls: [podcastFeedUrl]) { (mediaRefs) -> Void in
                    self.reloadClipData(mediaRefs: mediaRefs)
                }
            }
            self.filterType.setTitle("Podcast\u{2304}", for: .normal)
            self.filterTypeSelected = .podcast
            UserDefaults.standard.set("Podcast", forKey: kClipsListFilterType)
        }))
        
        
        alert.addAction(UIAlertAction(title: "Subscribed", style: .default, handler: { action in
            MediaRef.retrieveMediaRefsFromServer(episodeMediaUrl: nil, podcastFeedUrls: []) { (mediaRefs) -> Void in
                self.reloadClipData(mediaRefs: mediaRefs)
            }
            self.filterType.setTitle("Subscribed\u{2304}", for: .normal)
            self.filterTypeSelected = .subscribed
            UserDefaults.standard.set("Subscribed", forKey: kClipsListFilterType)
        }))
        
        alert.addAction(UIAlertAction(title: "All Podcasts", style: .default, handler: { action in
            MediaRef.retrieveMediaRefsFromServer(episodeMediaUrl: nil, podcastFeedUrls: []) { (mediaRefs) -> Void in
                self.reloadClipData(mediaRefs: mediaRefs)
            }
            self.filterType.setTitle("All Podcasts\u{2304}", for: .normal)
            self.filterTypeSelected = .allPodcasts
            UserDefaults.standard.set("All Podcasts", forKey: kClipsListFilterType)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func retrieveClipData() {
        showIndicator()
        if let item = pvMediaPlayer.nowPlayingItem {
            if self.filterTypeSelected == .allPodcasts {
                MediaRef.retrieveMediaRefsFromServer() { (mediaRefs) -> Void in
                    self.reloadClipData(mediaRefs: mediaRefs)
                }
            } else if self.filterTypeSelected == .subscribed {
                MediaRef.retrieveMediaRefsFromServer() { (mediaRefs) -> Void in
                    self.reloadClipData(mediaRefs: mediaRefs)
                }
            } else if self.filterTypeSelected == .podcast, let podcastFeedUrl = item.podcastFeedUrl {
                MediaRef.retrieveMediaRefsFromServer(podcastFeedUrls: [podcastFeedUrl]) { (mediaRefs) -> Void in
                    self.reloadClipData(mediaRefs: mediaRefs)
                }
            } else {
                MediaRef.retrieveMediaRefsFromServer(episodeMediaUrl: item.episodeMediaUrl) { (mediaRefs) -> Void in
                    self.reloadClipData(mediaRefs: mediaRefs)
                }
            }
        }
        else {
            MediaRef.retrieveMediaRefsFromServer() { (mediaRefs) -> Void in
                self.reloadClipData(mediaRefs: mediaRefs)
            }
        }
    }
    
    func checkForConnectvity() {
        var message = "No clips available"
        
        if self.reachability.hasInternetConnection() == false {
            message = "You must connect to the internet to load clips."
        }
        
        if let noDataView = self.view.subviews.first(where: { $0.tag == kNoDataViewTag}) {
            if let messageView = noDataView.subviews.first(where: {$0 is UILabel}), let messageLabel = messageView as? UILabel {
                messageLabel.text = message
            }
        }
        else {
            self.addNoDataViewWithMessage(message, buttonTitle: "Retry", buttonImage: nil, retryPressed: #selector(ClipsListContainerViewController.retrieveClipData))   
            if let noDataView = self.view.subviews.first(where: { $0.tag == kNoDataViewTag}) {
                noDataView.backgroundColor = .black
                if let messageView = noDataView.subviews.first(where: {$0 is UILabel}), let messageLabel = messageView as? UILabel {
                    messageLabel.textColor = .white
                }
                
                if let retryView = noDataView.subviews.first(where: {$0 is UIButton}), let retryButton = retryView as? UIButton {
                    retryButton.setTitleColor(.white, for: .normal)
                }
            }
        }
    }
    
    func reloadClipData(mediaRefs: [MediaRef]? = nil) {
        
        self.tableView.isHidden = true
        
        if let mediaRefArray = mediaRefs, mediaRefArray.count > 0 {
            self.clipsArray = mediaRefArray
            
            self.tableView.isHidden = false
        }
        
        self.activityIndicator.stopAnimating()
        self.tableView.reloadData()
    }
    
    func showIndicator() {
        activityIndicator.startAnimating()
        activityIndicator.isHidden = false
    }
}

extension ClipsListContainerViewController:UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return clipsArray.count
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let clip = clipsArray[indexPath.row]
        
        if filterTypeSelected == .episode {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "clipEpisodeCell", for: indexPath) as! ClipEpisodeTableViewCell
            
            cell.clipTitle?.text = clip.title
            
            if let time = clip.readableStartAndEndTime() {
                cell.time?.text = time
            }
            
            return cell
            
        } else if filterTypeSelected == .podcast {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "clipPodcastCell", for: indexPath) as! ClipPodcastTableViewCell
            
            cell.episodeTitle?.text = clip.episodeTitle
            cell.clipTitle?.text = clip.title
            
            if let episodePubDate = clip.episodePubDate {
                cell.episodePubDate?.text = episodePubDate.toShortFormatString()
            }
            
            if let time = clip.readableStartAndEndTime() {
                cell.time?.text = time
            }
            
            return cell
            
        } else {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "clipCell", for: indexPath) as! ClipTableViewCell
            
            cell.podcastTitle?.text = clip.podcastTitle
            cell.episodeTitle?.text = clip.episodeTitle
            cell.clipTitle?.text = clip.title
            
            cell.podcastImage.image = Podcast.retrievePodcastImage(podcastImageURLString: clip.podcastImageUrl, feedURLString: clip.podcastFeedUrl, managedObjectID: nil, completion: { _ in
                cell.podcastImage.sd_setImage(with: URL(string: clip.podcastImageUrl ?? ""), placeholderImage: #imageLiteral(resourceName: "PodverseIcon"))
            })
            
            if let episodePubDate = clip.episodePubDate {
                cell.episodePubDate?.text = episodePubDate.toShortFormatString()
            }
            
            if let time = clip.readableStartAndEndTime() {
                cell.time?.text = time
            }
            
            return cell
            
        }

    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
        self.delegate?.didSelectClip(clip: self.clipsArray[indexPath.row])
    }
}

