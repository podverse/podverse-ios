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
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewHeader: FiltersTableHeaderView!
    
    var clipsArray = [MediaRef]()
    weak var delegate:ClipsListDelegate?
    let pvMediaPlayer = PVMediaPlayer.shared
    let reachability = PVReachability.shared
    
    var filterTypeSelected: ClipFilter = .episode {
        didSet {
            self.tableViewHeader.filterTitle = filterTypeSelected.text
            UserDefaults.standard.set(filterTypeSelected.text, forKey: kClipsListFilterType)
        }
    }
    
    var sortingTypeSelected: ClipSorting = .topWeek {
        didSet {
            self.tableViewHeader.sortingTitle = sortingTypeSelected.text
            UserDefaults.standard.set(sortingTypeSelected.text, forKey: kClipsListSortingType)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableViewHeader.delegate = self
        self.tableViewHeader.setupViews(isBlackBg: true)
        
        self.tableView.separatorColor = .darkGray
        
        activityIndicator.hidesWhenStopped = true
        showIndicator()
        
        if let savedFilterType = UserDefaults.standard.value(forKey: kClipsListFilterType) as? String, let sFilterType = ClipFilter(rawValue: savedFilterType) {
            self.filterTypeSelected = sFilterType
        } else {
            self.filterTypeSelected = .episode
        }
        
        if let savedSortingType = UserDefaults.standard.value(forKey: kClipsListSortingType) as? String, let episodesSortingType = ClipSorting(rawValue: savedSortingType) {
            self.sortingTypeSelected = episodesSortingType
        } else {
            self.sortingTypeSelected = .topWeek
        }
        
        retrieveClips()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkForConnectvity()
    }
    
    func retrieveClipsAllPodcasts() {
        MediaRef.retrieveMediaRefsFromServer(sortingType: self.sortingTypeSelected) { (mediaRefs) -> Void in
            self.reloadClipData(mediaRefs: mediaRefs)
        }
        
        self.filterTypeSelected = .allPodcasts
        UserDefaults.standard.set(ClipFilter.allPodcasts.text, forKey: kClipsListFilterType)
    }
    
    func retrieveClipsSubscribed() {
        let subscribedPodcastFeedUrls = Podcast.retrieveSubscribedUrls()
        
        MediaRef.retrieveMediaRefsFromServer(episodeMediaUrl: nil, podcastFeedUrls: subscribedPodcastFeedUrls, sortingType: self.sortingTypeSelected) { (mediaRefs) -> Void in
            self.reloadClipData(mediaRefs: mediaRefs)
        }
        
        self.filterTypeSelected = .subscribed
        UserDefaults.standard.set(ClipFilter.subscribed.text, forKey: kClipsListFilterType)
    }
    
    func retrieveClipsPodcast(feedUrl: String) {
        MediaRef.retrieveMediaRefsFromServer(podcastFeedUrls: [feedUrl], sortingType: self.sortingTypeSelected) { (mediaRefs) -> Void in
            self.reloadClipData(mediaRefs: mediaRefs)
        }
        
        self.filterTypeSelected = .podcast
        UserDefaults.standard.set(ClipFilter.podcast.text, forKey: kClipsListFilterType)
    }
    
    func retrieveClipsEpisode(mediaUrl: String) {
        MediaRef.retrieveMediaRefsFromServer(episodeMediaUrl: mediaUrl, sortingType: self.sortingTypeSelected) { (mediaRefs) -> Void in
            self.reloadClipData(mediaRefs: mediaRefs)
        }
        
        self.filterTypeSelected = .episode
        UserDefaults.standard.set(ClipFilter.episode.text, forKey: kClipsListFilterType)
    }
    
    func retrieveClips() {
        showIndicator()
        if let item = pvMediaPlayer.nowPlayingItem {
            if self.filterTypeSelected == .allPodcasts {
                retrieveClipsAllPodcasts()
            } else if self.filterTypeSelected == .subscribed {
                retrieveClipsSubscribed()
            } else if self.filterTypeSelected == .podcast, let podcastFeedUrl = item.podcastFeedUrl {
                retrieveClipsPodcast(feedUrl: podcastFeedUrl)
            } else if let mediaUrl = item.episodeMediaUrl {
                retrieveClipsEpisode(mediaUrl: mediaUrl)
            }
        }
        else {
            retrieveClipsAllPodcasts()
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
            self.addNoDataViewWithMessage(message, buttonTitle: "Retry", buttonImage: nil, retryPressed: #selector(ClipsListContainerViewController.retrieveClips))
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

extension ClipsListContainerViewController: FilterSelectionProtocol {
    
    func filterButtonTapped() {
        
        let alert = UIAlertController(title: "Clips From", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: ClipFilter.episode.text, style: .default, handler: { action in
            if let item = self.pvMediaPlayer.nowPlayingItem, let mediaUrl = item.episodeMediaUrl {
                self.retrieveClipsEpisode(mediaUrl: mediaUrl)
            }
        }))
        
        alert.addAction(UIAlertAction(title: ClipFilter.podcast.text, style: .default, handler: { action in
            if let item = self.pvMediaPlayer.nowPlayingItem, let podcastFeedUrl = item.podcastFeedUrl {
                self.retrieveClipsPodcast(feedUrl: podcastFeedUrl)
            }
        }))
        
        alert.addAction(UIAlertAction(title: ClipFilter.subscribed.text, style: .default, handler: { action in
            self.retrieveClipsSubscribed()
        }))
        
        alert.addAction(UIAlertAction(title: ClipFilter.allPodcasts.text, style: .default, handler: { action in
            self.retrieveClipsAllPodcasts()
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
        
    }
    
    func sortingButtonTapped() {
        self.tableViewHeader.showSortByMenu(vc: self)
    }
    
    func sortByRecent() {
        self.sortingTypeSelected = .recent
        self.retrieveClips()
    }
    
    func sortByTop() {
        self.tableViewHeader.showSortByTimeRangeMenu(vc: self)
    }
    
    func sortByTopWithTimeRange(timeRange: SortingTimeRange) {
        
        if timeRange == .day {
            self.sortingTypeSelected = .topDay
        } else if timeRange == .week {
            self.sortingTypeSelected = .topWeek
        } else if timeRange == .month {
            self.sortingTypeSelected = .topMonth
        } else if timeRange == .year {
            self.sortingTypeSelected = .topYear
        } else if timeRange == .allTime {
            self.sortingTypeSelected = .topAllTime
        }
        
        self.retrieveClips()
        
    }
}
