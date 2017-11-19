//
//  EpisodeTableViewController.swift
//  Podverse
//
//  Created by Mitchell Downey on 10/1/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

import UIKit

class EpisodeTableViewController: PVViewController {

    var clipsArray = [MediaRef]()
    var feedUrl: String?
    var mediaUrl: String?
    let moc = CoreDataHelper.createMOCForThread(threadType: .mainThread)
    let reachability = PVReachability.shared
    
    var filterTypeSelected: EpisodeFilter = .showNotes {
        didSet {
            self.resetClipQuery()
            self.tableViewHeader.filterTitle = self.filterTypeSelected.text
            UserDefaults.standard.set(filterTypeSelected.text, forKey: kEpisodeTableFilterType)
            
            if filterTypeSelected == .showNotes {
                self.webView.isHidden = false
                self.tableViewHeader.sortingButton.isHidden = true
            } else {
                self.webView.isHidden = true
                self.tableViewHeader.sortingButton.isHidden = false
            }
        }
    }
    
    var sortingTypeSelected: ClipSorting = .topWeek {
        didSet {
            self.resetClipQuery()
            self.tableViewHeader.sortingTitle = sortingTypeSelected.text
            UserDefaults.standard.set(sortingTypeSelected.text, forKey: kEpisodeTableSortingType)
        }
    }
    
    var clipQueryPage:Int = 0
    var clipQueryIsLoading:Bool = false
    var clipQueryEndOfResultsReached:Bool = false
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var activityView: UIView!
    @IBOutlet weak var episodeTitle: UILabel!
    @IBOutlet weak var headerImageView: UIImageView!
    @IBOutlet weak var localMultiButton: UIButton!
    @IBOutlet weak var streamButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewHeader: FiltersTableHeaderView!
    @IBOutlet weak var webView: UIWebView!
    
    @IBOutlet weak var clipQueryActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var clipQueryMessage: UILabel!
    @IBOutlet weak var clipQueryStatusView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Episode"
        
        setupNotificationListeners()
        
        self.activityIndicator.hidesWhenStopped = true
        
        self.tableViewHeader.delegate = self
        self.tableViewHeader.setupViews()
        
        self.clipQueryActivityIndicator.hidesWhenStopped = true
        self.clipQueryMessage.isHidden = true
        
        if let savedFilterType = UserDefaults.standard.value(forKey: kEpisodeTableFilterType) as? String, let episodeFilterType = EpisodeFilter(rawValue: savedFilterType) {
            self.filterTypeSelected = episodeFilterType
        } else {
            self.filterTypeSelected = .showNotes
        }
        
        if let savedSortingType = UserDefaults.standard.value(forKey: kEpisodeTableSortingType) as? String, let episodesSortingType = ClipSorting(rawValue: savedSortingType) {
            self.sortingTypeSelected = episodesSortingType
        } else {
            self.sortingTypeSelected = .topWeek
        }
        
        loadPodcastHeader()
        
        reloadShowNotesOrClipData()
        
    }
    
    deinit {
        removeObservers()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.webView.scrollView.contentInset = UIEdgeInsets.zero
    }
    
    fileprivate func setupNotificationListeners() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.downloadStarted(_:)), name: .downloadStarted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.downloadResumed(_:)), name: .downloadResumed, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.downloadPaused(_:)), name: .downloadPaused, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.downloadFinished(_:)), name: .downloadFinished, object: nil)
    }
    
    fileprivate func removeObservers() {
        NotificationCenter.default.removeObserver(self, name: .downloadStarted, object: nil)
        NotificationCenter.default.removeObserver(self, name: .downloadResumed, object: nil)
        NotificationCenter.default.removeObserver(self, name: .downloadPaused, object: nil)
        NotificationCenter.default.removeObserver(self, name: .downloadFinished, object: nil)
    }
    
    @IBAction func stream(_ sender: Any) {
        if let mediaUrl = self.mediaUrl, let episode = Episode.episodeForMediaUrl(mediaUrlString: mediaUrl, managedObjectContext: self.moc) {
            let item = playerHistoryManager.convertEpisodeToPlayerHistoryItem(episode: episode)
            
            goToNowPlaying()
            
            self.pvMediaPlayer.loadPlayerHistoryItem(item: item)
        }
    }
    
    @IBAction func downloadPlay(_ sender: Any) {
        
        if let mediaUrl = self.mediaUrl, let episode = Episode.episodeForMediaUrl(mediaUrlString: mediaUrl, managedObjectContext: self.moc) {
            
            if episode.fileName != nil {
                
                let playerHistoryItem: PlayerHistoryItem?
                
                if let mediaUrl = episode.mediaUrl, let item = playerHistoryManager.retrieveExistingPlayerHistoryItem(mediaUrl: mediaUrl) {
                    playerHistoryItem = item
                } else {
                    playerHistoryItem = playerHistoryManager.convertEpisodeToPlayerHistoryItem(episode: episode)
                }
                
                goToNowPlaying()
                
                if let item = playerHistoryItem {
                    self.pvMediaPlayer.loadPlayerHistoryItem(item: item)
                }
                
            } else {
                if reachability.hasWiFiConnection() == false {
                    showInternetNeededAlertWithDescription(message: "Connect to WiFi to download an episode.")
                    return
                }
                PVDownloader.shared.startDownloadingEpisode(episode: episode)
            }
            
        }
    }
    
    func loadPodcastHeader() {
        if let feedUrl = feedUrl, let podcast = Podcast.podcastForFeedUrl(feedUrlString: feedUrl, managedObjectContext: moc), let mediaUrl = mediaUrl, let episode = Episode.episodeForMediaUrl(mediaUrlString: mediaUrl, managedObjectContext: moc) {
            
            self.episodeTitle.text = episode.title
            
            self.headerImageView.image = Podcast.retrievePodcastImage(podcastImageURLString: podcast.imageUrl, feedURLString: podcast.feedUrl, completion: { image in
                self.headerImageView.image = image
            })
            
            // Set Play / Downloading / Download / Stream button titles
            if episode.fileName != nil {
                self.streamButton.isHidden = true
                self.localMultiButton.setTitle(EpisodeActions.play.text, for: .normal)
            } else if (DownloadingEpisodeList.shared.downloadingEpisodes.contains(where: {$0.mediaUrl == mediaUrl})) {
                self.streamButton.isHidden = false
                self.streamButton.setTitle(EpisodeActions.stream.text, for: .normal)
                self.localMultiButton.setTitle(EpisodeActions.downloading.text, for: .normal)
            } else {
                self.streamButton.isHidden = false
                self.streamButton.setTitle(EpisodeActions.stream.text, for: .normal)
                self.localMultiButton.setTitle(EpisodeActions.download.text, for: .normal)
            }

        }
    }
    
    func reloadShowNotesOrClipData() {
        if self.filterTypeSelected == .clips {
            retrieveClips()
        } else {
            reloadShowNotes()
        }
    }
    
    func reloadShowNotes() {
        
        self.hideNoDataView()
        self.webView.delegate = self
        self.webView.isHidden = false
        self.tableView.isHidden = true
        
        if let mediaUrl = self.mediaUrl, let episode = Episode.episodeForMediaUrl(mediaUrlString: mediaUrl, managedObjectContext: self.moc) {
            
            if var summary = episode.summary {
                
                if summary.trimmingCharacters(in: .whitespacesAndNewlines).count == 0 {
                    summary += kNoShowNotesMessage
                    self.webView.loadHTMLString(summary.formatHtmlString(isWhiteBg: true), baseURL: nil)
                } else {
                    // add linebreaks to account for the NowPlayingBar on the bottom of the screen
                    summary += "<br><br>"
                    self.webView.loadHTMLString(summary.formatHtmlString(isWhiteBg: true), baseURL: nil)
                }
                
            }
            
        }
        
    }
    
    func resetClipQuery() {
        self.clipsArray.removeAll()
        self.clipQueryPage = 0
        self.clipQueryIsLoading = true
        self.clipQueryEndOfResultsReached = false
        self.clipQueryMessage.isHidden = true
    }
    
    func retrieveClips() {
        
        guard checkForConnectivity() else {
            loadNoInternetMessage()
            return
        }
        
        self.webView.isHidden = true
        self.tableView.isHidden = false
        
        self.hideNoDataView()
        
        if self.clipQueryPage == 0 {
            showActivityIndicator()
        }
        
        self.clipQueryPage += 1
        
        if let mediaUrl = self.mediaUrl {
            MediaRef.retrieveMediaRefsFromServer(episodeMediaUrl: mediaUrl, sortingType: self.sortingTypeSelected, page: self.clipQueryPage) { (mediaRefs) -> Void in
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
            self.addNoDataViewWithMessage(message, buttonTitle: buttonTitle, buttonImage: nil, retryPressed: buttonPressed)
        }
        
        showNoDataView()
        
    }
    
    func loadNoInternetMessage() {
        loadNoDataView(message: Strings.Errors.noClipsInternet, buttonTitle: "Retry", buttonPressed: #selector(EpisodeTableViewController.reloadShowNotesOrClipData))
    }
    
    func loadNoClipsMessage() {
        loadNoDataView(message: Strings.Errors.noEpisodeClipsAvailable, buttonTitle: nil, buttonPressed: nil)
    }
    
    func showActivityIndicator() {
        self.tableView.isHidden = true
        self.activityIndicator.startAnimating()
        self.activityView.isHidden = false
    }
    
    func hideActivityIndicator() {
        self.activityIndicator.stopAnimating()
        self.activityView.isHidden = true
    }
    
    override func goToNowPlaying () {
        if let mediaPlayerVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MediaPlayerVC") as? MediaPlayerViewController {
            pvMediaPlayer.shouldAutoplayOnce = true
            self.navigationController?.pushViewController(mediaPlayerVC, animated: true)
        }
    }
    
}

extension EpisodeTableViewController:UIWebViewDelegate {
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if navigationType == UIWebViewNavigationType.linkClicked {
            if let url = request.url {
                UIApplication.shared.openURL(url)
            }
            return false
        }
        return true
    }
}

extension EpisodeTableViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.clipsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath as IndexPath) as! ClipEpisodeTableViewCell
        
        let clip = clipsArray[indexPath.row]
        
        cell.clipTitle.text = clip.readableClipTitle()
        cell.time.text = clip.readableStartAndEndTime()
        
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let clip = clipsArray[indexPath.row]
        let playerHistoryItem = self.playerHistoryManager.convertMediaRefToPlayerHistoryItem(mediaRef: clip)
        self.goToNowPlaying()
        self.pvMediaPlayer.loadPlayerHistoryItem(item: playerHistoryItem)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Bottom Refresh
        if scrollView == self.tableView && self.filterTypeSelected == .clips {
            if ((scrollView.contentOffset.y + scrollView.frame.size.height) >= scrollView.contentSize.height) && !self.clipQueryIsLoading && !self.clipQueryEndOfResultsReached {
                self.clipQueryIsLoading = true
                self.clipQueryActivityIndicator.startAnimating()
                self.retrieveClips()
            }
        }
    }
    
}

extension EpisodeTableViewController {
    
    func updateButtonsByNotification(_ notification:Notification) {
        if let downloadingEpisode = notification.userInfo?[Episode.episodeKey] as? DownloadingEpisode, let dlMediaUrl = downloadingEpisode.mediaUrl, let mediaUrl = self.mediaUrl, dlMediaUrl == mediaUrl {
            loadPodcastHeader()
        }
    }
    
    func downloadFinished(_ notification:Notification) {
        updateButtonsByNotification(notification)
    }
    
    func downloadPaused(_ notification:Notification) {
        updateButtonsByNotification(notification)
    }
    
    func downloadResumed(_ notification:Notification) {
        updateButtonsByNotification(notification)
    }
    
    func downloadStarted(_ notification:Notification) {
        updateButtonsByNotification(notification)
    }
        
}

extension EpisodeTableViewController:FilterSelectionProtocol {
    
    func filterButtonTapped() {
        
        let alert = UIAlertController(title: "From this Episode", message: nil, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: EpisodeFilter.showNotes.text, style: .default, handler: { action in
            self.filterTypeSelected = .showNotes
            self.reloadShowNotes()
        }))
        
        alert.addAction(UIAlertAction(title: EpisodeFilter.clips.text, style: .default, handler: { action in
            self.filterTypeSelected = .clips
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
