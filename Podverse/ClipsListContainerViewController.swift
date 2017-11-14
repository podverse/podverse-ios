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

    var clipsArray = [MediaRef]()
    weak var delegate:ClipsListDelegate?
    let pvMediaPlayer = PVMediaPlayer.shared
    let reachability = PVReachability.shared
    
    var filterTypeSelected: ClipFilter = .episode {
        didSet {
            self.resetClipQuery()
            self.tableViewHeader.filterTitle = filterTypeSelected.text
            UserDefaults.standard.set(filterTypeSelected.text, forKey: kClipsListFilterType)
        }
    }
    
    var sortingTypeSelected: ClipSorting = .topWeek {
        didSet {
            self.resetClipQuery()
            self.tableViewHeader.sortingTitle = sortingTypeSelected.text
            UserDefaults.standard.set(sortingTypeSelected.text, forKey: kClipsListSortingType)
        }
    }
    
    var clipQueryPage: Int = 0
    var clipQueryIsLoading: Bool = false
    var clipQueryEndOfResultsReached: Bool = false
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var activityView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewHeader: FiltersTableHeaderView!
    
    @IBOutlet weak var clipQueryActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var clipQueryMessage: UILabel!
    @IBOutlet weak var clipQueryStatusView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        activityIndicator.hidesWhenStopped = true
        
        self.tableViewHeader.delegate = self
        self.tableViewHeader.setupViews(isBlackBg: true)
        
        self.tableView.separatorColor = .darkGray
        
        self.clipQueryActivityIndicator.hidesWhenStopped = true
        self.clipQueryMessage.isHidden = true
        
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
    
    func resetClipQuery() {
        self.clipsArray.removeAll()
        self.clipQueryPage = 0
        self.clipQueryIsLoading = true
        self.clipQueryEndOfResultsReached = false
        self.clipQueryMessage.isHidden = true
        self.tableView.reloadData()
    }
    
    func retrieveClips() {
        
        guard checkForConnectivity() else {
            loadNoInternetMessage()
            return
        }
        
        self.hideNoDataView()
        
        if self.clipQueryPage == 0 {
            showActivityIndicator()
        }
        
        self.clipQueryPage += 1
        
        if self.filterTypeSelected == .episode, let item = pvMediaPlayer.nowPlayingItem, let mediaUrl = item.episodeMediaUrl {
            
            MediaRef.retrieveMediaRefsFromServer(episodeMediaUrl: mediaUrl, sortingType: self.sortingTypeSelected, page: self.clipQueryPage) { (mediaRefs) -> Void in
                self.reloadClipData(mediaRefs)
            }
            
        } else if self.filterTypeSelected == .podcast, let item = pvMediaPlayer.nowPlayingItem, let feedUrl = item.podcastFeedUrl {
            
            MediaRef.retrieveMediaRefsFromServer(podcastFeedUrls: [feedUrl], sortingType: self.sortingTypeSelected, page: self.clipQueryPage) { (mediaRefs) -> Void in
                self.reloadClipData(mediaRefs)
            }
            
        } else if self.filterTypeSelected == .subscribed {
            
            let subscribedPodcastFeedUrls = Podcast.retrieveSubscribedUrls()
            
            if subscribedPodcastFeedUrls.count < 1 {
                self.reloadClipData()
                return
            }
            
            MediaRef.retrieveMediaRefsFromServer(episodeMediaUrl: nil, podcastFeedUrls: subscribedPodcastFeedUrls, sortingType: self.sortingTypeSelected, page: self.clipQueryPage) { (mediaRefs) -> Void in
                self.reloadClipData(mediaRefs)
            }
            
        } else {
            
            MediaRef.retrieveMediaRefsFromServer(sortingType: self.sortingTypeSelected, page: self.clipQueryPage) { (mediaRefs) -> Void in
                self.reloadClipData(mediaRefs)
            }
            
        }
        
    }
    
    func reloadClipData(_ mediaRefs: [MediaRef]? = nil) {
        
        hideActivityIndicator()
        self.clipQueryIsLoading = false
        self.clipQueryActivityIndicator.stopAnimating()
        
        guard checkForResults(results: mediaRefs) || checkForResults(results: self.clipsArray), let mediaRefs = mediaRefs else {
            loadNoClipsMessage()
            return
        }
        
        guard checkForResults(results: mediaRefs) else {
            self.clipQueryEndOfResultsReached = true
            self.clipQueryMessage.isHidden = false
            return
        }
        
        for mediaRef in mediaRefs {
            self.clipsArray.append(mediaRef)
        }
        
        self.tableView.isHidden = false
        self.tableView.reloadData()
        
    }
    
    func loadNoDataView(message: String, buttonTitle: String?, buttonPressed: Selector?) {
        
        if let noDataView = self.view.subviews.first(where: { $0.tag == kNoDataViewTag}) {
            
            if let messageView = noDataView.subviews.first(where: {$0 is UILabel}), let messageLabel = messageView as? UILabel {
                messageLabel.text = message
            }
            
            if let buttonView = noDataView.subviews.first(where: {$0 is UIButton}), let button = buttonView as? UIButton {
                button.setTitle(buttonTitle, for: .normal)
            }
        }
        else {
            self.addNoDataViewWithMessage(message, buttonTitle: buttonTitle, buttonImage: nil, retryPressed: buttonPressed, isBlackBg: true)
        }
        
        showNoDataView()
        
    }
    
    func loadNoInternetMessage() {
        loadNoDataView(message: Strings.Errors.noClipsInternet, buttonTitle: "Retry", buttonPressed: #selector(ClipsListContainerViewController.retrieveClips))
    }
    
    func loadNoClipsMessage() {
        loadNoDataView(message: Strings.Errors.noClipsAvailable, buttonTitle: nil, buttonPressed: nil)
    }
    
    func showActivityIndicator() {
        self.activityIndicator.startAnimating()
        self.activityView.isHidden = false
    }
    
    func hideActivityIndicator() {
        self.activityIndicator.stopAnimating()
        self.activityView.isHidden = true
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
            
            cell.podcastImage.image = Podcast.retrievePodcastImage(podcastImageURLString: clip.podcastImageUrl, feedURLString: clip.podcastFeedUrl, managedObjectID: nil, completion: { image in
                cell.podcastImage.image = image
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
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Bottom Refresh
        if scrollView == self.tableView {
            if ((scrollView.contentOffset.y + scrollView.frame.size.height) >= scrollView.contentSize.height) && !self.clipQueryIsLoading && !self.clipQueryEndOfResultsReached {
                self.clipQueryIsLoading = true
                self.clipQueryActivityIndicator.startAnimating()
                self.retrieveClips()
            }
        }
    }
}

extension ClipsListContainerViewController: FilterSelectionProtocol {
    
    func filterButtonTapped() {
        
        let alert = UIAlertController(title: "Clips From", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: ClipFilter.episode.text, style: .default, handler: { action in
            self.filterTypeSelected = .episode
            self.retrieveClips()
        }))
        
        alert.addAction(UIAlertAction(title: ClipFilter.podcast.text, style: .default, handler: { action in
            self.filterTypeSelected = .podcast
            self.retrieveClips()
        }))
        
        alert.addAction(UIAlertAction(title: ClipFilter.subscribed.text, style: .default, handler: { action in
            self.filterTypeSelected = .subscribed
            self.retrieveClips()
        }))
        
        alert.addAction(UIAlertAction(title: ClipFilter.allPodcasts.text, style: .default, handler: { action in
            self.filterTypeSelected = .allPodcasts
            self.retrieveClips()
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
