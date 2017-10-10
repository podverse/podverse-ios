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
    let moc = CoreDataHelper.createMOCForThread(threadType: .privateThread)
    let reachability = PVReachability.shared
    
    var filterTypeSelected: EpisodeFilter = .showNotes {
        didSet {
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
            self.tableViewHeader.sortingTitle = sortingTypeSelected.text
            UserDefaults.standard.set(sortingTypeSelected.text, forKey: kEpisodeTableSortingType)
        }
    }
    
    @IBOutlet weak var episodeTitle: UILabel!
    @IBOutlet weak var headerImageView: UIImageView!

    @IBOutlet weak var localMultiButton: UIButton!
    @IBOutlet weak var streamButton: UIButton!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewHeader: FiltersTableHeaderView!
    @IBOutlet weak var webView: UIWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableViewHeader.delegate = self
        self.tableViewHeader.setupViews()
        
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
        
        setupNotificationListeners()
        
        loadPodcastHeader()
        
        reloadShowNotesOrClipData()
        
    }
    
    deinit {
        removeObservers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.tableViewHeader.filterTitle = self.filterTypeSelected.text
        self.tableViewHeader.sortingTitle = self.sortingTypeSelected.text
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.webView.scrollView.contentInset = UIEdgeInsets.zero;
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
                    showInternetNeededAlertWithDesciription(message: "Connect to WiFi to download an episode.")
                    return
                }
                PVDownloader.shared.startDownloadingEpisode(episode: episode)
            }
            
        }
    }
    
    @IBAction func stream(_ sender: Any) {
        if let mediaUrl = self.mediaUrl, let episode = Episode.episodeForMediaUrl(mediaUrlString: mediaUrl, managedObjectContext: self.moc) {
            let item = playerHistoryManager.convertEpisodeToPlayerHistoryItem(episode: episode)
            
            goToNowPlaying()
            
            self.pvMediaPlayer.loadPlayerHistoryItem(item: item)
        }
    }
    
    func loadPodcastHeader() {
        if let feedUrl = feedUrl, let podcast = Podcast.podcastForFeedUrl(feedUrlString: feedUrl, managedObjectContext: moc), let mediaUrl = mediaUrl, let episode = Episode.episodeForMediaUrl(mediaUrlString: mediaUrl, managedObjectContext: moc) {
            
            episodeTitle.text = episode.title
            
            self.headerImageView.image = Podcast.retrievePodcastImage(podcastImageURLString: podcast.imageUrl, feedURLString: podcast.feedUrl, managedObjectID: podcast.objectID, completion: { _ in
                self.headerImageView.sd_setImage(with: URL(string: podcast.imageUrl ?? ""), placeholderImage: #imageLiteral(resourceName: "PodverseIcon"))
            })
            
            // Set Stream / Download / Downloading / Play button titles
            if (DownloadingEpisodeList.shared.downloadingEpisodes.contains(where: {$0.mediaUrl == mediaUrl})) {
                self.streamButton.isHidden = false
                self.streamButton.setTitle(EpisodeActions.stream.title, for: .normal)
                self.localMultiButton.setTitle(EpisodeActions.downloading.title, for: .normal)
            } else if episode.fileName == nil {
                self.streamButton.isHidden = false
                self.streamButton.setTitle(EpisodeActions.stream.title, for: .normal)
                self.localMultiButton.setTitle(EpisodeActions.download.title, for: .normal)
            } else {
                self.streamButton.isHidden = true
                self.localMultiButton.setTitle(EpisodeActions.play.title, for: .normal)
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
    
    func retrieveClips() {
        
        self.webView.isHidden = true
        self.tableView.isHidden = false
        
        if let mediaUrl = self.mediaUrl {
            MediaRef.retrieveMediaRefsFromServer(episodeMediaUrl: mediaUrl, sortingType: self.sortingTypeSelected, page: 1) { (mediaRefs) -> Void in
                
                self.clipsArray.removeAll()
                
                if let mediaRefs = mediaRefs {
                    self.clipsArray = mediaRefs
                }
                
                self.reloadClipData()
            }
        }
        
    }
    
    func reloadClipData() {
        // TODO: Handle infinite scroll logic here
        self.tableView.reloadData()
    }
    
    func reloadShowNotes() {
        self.clipsArray.removeAll()
        
        if let mediaUrl = self.mediaUrl, let episode = Episode.episodeForMediaUrl(mediaUrlString: mediaUrl, managedObjectContext: self.moc) {
            
            if var summary = episode.summary {
                
                if summary.trimmingCharacters(in: .whitespacesAndNewlines).characters.count == 0 {
                    summary += kNoShowNotesMessage
                    self.webView.loadHTMLString(summary.formatHtmlString(isWhiteBg: true), baseURL: nil)
                } else {
                    // add linebreaks to account for the NowPlayingBar on the bottom of the screen
                    summary += "<br><br>"
                    self.webView.loadHTMLString(summary.formatHtmlString(isWhiteBg: true), baseURL: nil)
                }
                
            }
            
            self.webView.delegate = self
            
            self.tableView.isHidden = true
            self.webView.isHidden = false
        }
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
