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
    
    var filterTypeSelected: ClipFilterType = .episode {
        didSet {
            self.filterType.setTitle(filterTypeSelected.text + "\u{2304}", for: .normal)
            UserDefaults.standard.set(filterTypeSelected.text, forKey: kClipsListFilterType)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.separatorColor = UIColor.darkGray
        
        activityIndicator.hidesWhenStopped = true
        showIndicator()
        
        if let savedFilterType = UserDefaults.standard.value(forKey: kClipsListFilterType) as? String, let sFilterType = ClipFilterType(rawValue: savedFilterType) {
            self.filterTypeSelected = sFilterType
        }
        
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
    }
    
    @IBAction func retryButtonTouched(_ sender: Any) {
        
    }
    
    @IBAction func updateFilter(_ sender: Any) {
        let alert = UIAlertController(title: "Clips From", message: nil, preferredStyle: .alert)

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
    
    
    func reloadClipData(mediaRefs: [MediaRef]? = nil) {
        if self.reachability.hasInternetConnection() == false {
            self.showStatusMessage(message: "You must connect to the internet to load clips.")
            return
        }
        
        guard let mediaRefArray = mediaRefs, mediaRefArray.count > 0 else {
            self.showStatusMessage(message: "No clips available")
            return
        }
        
        self.clipsArray.removeAll()
        
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

