import UIKit
import CoreData

protocol AutoDownloadProtocol: NSObjectProtocol {
    func podcastAutodownloadChanged(feedUrl: String)
}

class EpisodesTableViewController: PVViewController {
    
    var audiosearchId:Int64?
    var clipsArray = [MediaRef]()
    weak var delegate: AutoDownloadProtocol?
    var episodesArray = [Episode]()
    var feedUrl: String?
    let moc = CoreDataHelper.createMOCForThread(threadType: .mainThread)
    let reachability = PVReachability.shared
    
    var filterTypeSelected: EpisodesFilter = .downloaded {
        didSet {
            self.resetClipQuery()
            self.tableViewHeader.filterTitle = self.filterTypeSelected.text
            
            if filterTypeSelected == .clips {
                self.tableViewHeader.sortingButton.isHidden = false
                self.clipQueryStatusView.isHidden = false
            } else {
                self.tableViewHeader.sortingButton.isHidden = true
                self.clipQueryStatusView.isHidden = true
            }
        }
    }
    
    var sortingTypeSelected: ClipSorting = .topWeek {
        didSet {
            self.resetClipQuery()
            self.tableViewHeader.sortingTitle = sortingTypeSelected.text
            UserDefaults.standard.set(sortingTypeSelected.text, forKey: kEpisodesTableSortingType)
        }
    }
    
    var clipQueryPage:Int = 0
    var clipQueryIsLoading:Bool = false
    var clipQueryEndOfResultsReached:Bool = false
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var activityView: UIView!
    @IBOutlet weak var autoDownloadLabel: UILabel!
    @IBOutlet weak var autoDownloadSwitch: UISwitch!
    @IBOutlet weak var bottomButton: UITableView!
    @IBOutlet weak var headerImageView: UIImageView!
    @IBOutlet weak var headerPodcastTitle: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewHeader: FiltersTableHeaderView!
    @IBOutlet weak var webView: UIWebView!
    
    @IBOutlet weak var clipQueryActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var clipQueryMessage: UILabel!
    @IBOutlet weak var clipQueryStatusView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNotificationListeners()
        
        self.activityIndicator.hidesWhenStopped = true
        
        self.tableViewHeader.delegate = self
        self.tableViewHeader.setupViews()
        
        self.clipQueryActivityIndicator.hidesWhenStopped = true
        self.clipQueryMessage.isHidden = true
        
        self.filterTypeSelected = .downloaded
        
        if let savedSortingType = UserDefaults.standard.value(forKey: kEpisodesTableSortingType) as? String, let episodesSortingType = ClipSorting(rawValue: savedSortingType) {
            self.sortingTypeSelected = episodesSortingType
        } else {
            self.sortingTypeSelected = .topWeek
        }
        
        loadPodcastHeader()
        
        reloadEpisodeOrClipData()
        
        loadAbout()
        
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.webView.scrollView.contentInset = UIEdgeInsets.zero
    }
    
    deinit {
        removeObservers()
    }
    
    fileprivate func setupNotificationListeners() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.downloadStarted(_:)), name: .downloadStarted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.downloadResumed(_:)), name: .downloadResumed, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.downloadPaused(_:)), name: .downloadPaused, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.downloadCanceled(_:)), name: .downloadCanceled, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.downloadFinished(_:)), name: .downloadFinished, object: nil)
    }
    
    fileprivate func removeObservers() {
        NotificationCenter.default.removeObserver(self, name: .downloadStarted, object: nil)
        NotificationCenter.default.removeObserver(self, name: .downloadResumed, object: nil)
        NotificationCenter.default.removeObserver(self, name: .downloadPaused, object: nil)
        NotificationCenter.default.removeObserver(self, name: .downloadCanceled, object: nil)
        NotificationCenter.default.removeObserver(self, name: .downloadFinished, object: nil)
    }
    
    @IBAction func autoDownloadSwitchTouched(_ sender: Any) {
        if let feedUrl = feedUrl, let podcast = Podcast.podcastForFeedUrl(feedUrlString: feedUrl, managedObjectContext: moc) {
            if podcast.shouldAutoDownload() {
                podcast.removeFromAutoDownloadList()
            } else {
                podcast.addToAutoDownloadList()
            }
            self.delegate?.podcastAutodownloadChanged(feedUrl: podcast.feedUrl)
        }
    }
    
    func downloadPlay(sender: UIButton) {
        if let cell = sender.superview?.superview as? EpisodeTableViewCell,
            let indexRow = self.tableView.indexPath(for: cell)?.row {
            
            let episode = episodesArray[indexRow]
            if episode.fileName != nil {
                
                let playerHistoryItem: PlayerHistoryItem?
                
                if let mediaUrl = episode.mediaUrl, let item = playerHistoryManager.retrieveExistingPlayerHistoryItem(mediaUrl: mediaUrl) {
                    playerHistoryItem = item
                } else {
                    playerHistoryItem = playerHistoryManager.convertEpisodeToPlayerHistoryItem(episode: episode)
                }
                
                goToNowPlaying()
                
                if let item = playerHistoryItem {
                    pvMediaPlayer.loadPlayerHistoryItem(item: item)
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
        if let feedUrl = feedUrl, let podcast = Podcast.podcastForFeedUrl(feedUrlString: feedUrl, managedObjectContext: moc) {
            
            self.headerPodcastTitle.text = podcast.title
            
            self.headerImageView.image = Podcast.retrievePodcastImage(podcastImageURLString: podcast.imageUrl, feedURLString: podcast.feedUrl, managedObjectID: podcast.objectID, completion: { _ in
                self.headerImageView.sd_setImage(with: URL(string: podcast.imageUrl ?? ""), placeholderImage: #imageLiteral(resourceName: "PodverseIcon"))
            })
            
            self.autoDownloadSwitch.isOn = podcast.shouldAutoDownload() ? true : false
        }
    }
    
    func reloadEpisodeOrClipData() {
        if self.filterTypeSelected == .clips {
            retrieveClips()
        } else {
            reloadEpisodeData()
        }
    }
    
    func loadAbout() {
        if let feedUrl = feedUrl, let podcast = Podcast.podcastForFeedUrl(feedUrlString: feedUrl, managedObjectContext: moc) {
            
            self.webView.delegate = self
            
            var htmlString = ""
            
            htmlString += "<strong>" + podcast.title + "</strong>"
            htmlString += "<br><br>"

            if let categories = podcast.categories {
                htmlString += "<i>" + categories + "</i>"
                htmlString += "<br><br>"
            }
            
            if let summary = podcast.summary {
                
                if summary.trimmingCharacters(in: .whitespacesAndNewlines).characters.count == 0 {
                    htmlString += kNoPodcastAboutMessage
                } else {
                    htmlString += summary
                }
                
                htmlString += "<br><br>"
                
            }
            
            htmlString += "<br><br>" // add extra line breaks so NowPlayingBar doesn't cover the about text
            
            self.webView.loadHTMLString(htmlString.formatHtmlString(isWhiteBg: true), baseURL: nil)
            
            if self.filterTypeSelected == .about {
                self.showAbout()
            }
        }
    }
    
    
    
    func loadAllEpisodeData() {
        self.filterTypeSelected = .allEpisodes
        reloadEpisodeData()
    }
    
    func reloadEpisodeData() {
        
        self.hideNoDataView()
        self.tableView.isHidden = false
        
        if let feedUrl = feedUrl, let podcast = Podcast.podcastForFeedUrl(feedUrlString: feedUrl, managedObjectContext: moc) {
            
            self.episodesArray.removeAll()
            
            if self.filterTypeSelected == .downloaded {
                self.episodesArray = Array(podcast.episodes.filter { $0.fileName != nil } )
                let downloadingEpisodes = DownloadingEpisodeList.shared.downloadingEpisodes.filter({$0.podcastFeedUrl == podcast.feedUrl})
                
                for dlEpisode in downloadingEpisodes {
                    if let mediaUrl = dlEpisode.mediaUrl, let episode = Episode.episodeForMediaUrl(mediaUrlString: mediaUrl, managedObjectContext: self.moc), !self.episodesArray.contains(episode) {
                        self.episodesArray.append(episode)
                    }
                }
                
                guard checkForResults(results: episodesArray) else {
                    self.loadNoDownloadedEpisodesMessage()
                    return
                }
                
            } else if self.filterTypeSelected == .allEpisodes {
                self.episodesArray = Array(podcast.episodes)

                guard checkForResults(results: self.episodesArray) else {
                    self.loadNoEpisodesMessage()
                    return
                }
            }
            
            episodesArray.sort(by: { (prevEp, nextEp) -> Bool in
                if let prevTimeInterval = prevEp.pubDate, let nextTimeInterval = nextEp.pubDate {
                    return (prevTimeInterval > nextTimeInterval)
                }
                
                return false
            })
            
            self.tableView.reloadData()
            
        }
        
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

        self.episodesArray.removeAll()
        self.tableView.reloadData()
        
        self.hideNoDataView()
        
        if self.clipQueryPage == 0 {
            showActivityIndicator()
        }
        
        self.clipQueryPage += 1
        
        if let feedUrl = feedUrl {
            MediaRef.retrieveMediaRefsFromServer(podcastFeedUrls: [feedUrl], sortingType: self.sortingTypeSelected, page: self.clipQueryPage) { (mediaRefs) -> Void in
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
        
        self.tableView.isHidden = true
        self.webView.isHidden = true
        
        showNoDataView()
        
    }

    func loadNoInternetMessage() {
        loadNoDataView(message: Strings.Errors.noClipsInternet, buttonTitle: "Retry", buttonPressed: #selector(EpisodesTableViewController.reloadEpisodeOrClipData))
    }
    
    func loadNoClipsMessage() {
        loadNoDataView(message: Strings.Errors.noPodcastClipsAvailable, buttonTitle: nil, buttonPressed: nil)
    }
    
    func loadNoEpisodesMessage() {
        loadNoDataView(message: Strings.Errors.noEpisodesAvailable, buttonTitle: nil, buttonPressed: nil)
    }
    
    func loadNoDownloadedEpisodesMessage() {
        loadNoDataView(message: Strings.Errors.noDownloadedEpisodesAvailable, buttonTitle: "Show All Episodes", buttonPressed: #selector(EpisodesTableViewController.loadAllEpisodeData))
    }
    
    func showAbout() {
        DispatchQueue.main.async {
            self.hideNoDataView()
            self.activityView.isHidden = true
            self.tableView.isHidden = true
            self.webView.isHidden = false
        }
    }
    
    func showActivityIndicator() {
        self.activityIndicator.startAnimating()
        self.activityView.isHidden = false
        self.tableView.isHidden = true
        self.webView.isHidden = true
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Show Episode" {
            if let episodeTableViewController = segue.destination as? EpisodeTableViewController, let feedUrl = self.feedUrl, let index = self.tableView.indexPathForSelectedRow {
                episodeTableViewController.feedUrl = feedUrl
                episodeTableViewController.mediaUrl = self.episodesArray[index.row].mediaUrl
            }
        }
    }
}

extension EpisodesTableViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if self.filterTypeSelected == .clips {
            return self.clipsArray.count
        } else {
            return self.episodesArray.count
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if self.filterTypeSelected == .clips {
            
            let cell = self.tableView.dequeueReusableCell(withIdentifier: "clipCell", for: indexPath as IndexPath) as! ClipPodcastTableViewCell
            
            let clip = clipsArray[indexPath.row]
            
            cell.episodeTitle.text = clip.episodeTitle
            cell.clipTitle.text = clip.readableClipTitle()
            cell.time.text = clip.readableStartAndEndTime()
            cell.episodePubDate.text = clip.episodePubDate?.toShortFormatString()
            
            return cell
            
        } else {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "episodeCell", for: indexPath as IndexPath) as! EpisodeTableViewCell
            
            let episode = episodesArray[indexPath.row]
            
            cell.title?.text = episode.title
            
            if let summary = episode.summary {
                
                let trimmed = summary.replacingOccurrences(of: "\\n*", with: "", options: .regularExpression)
                
                cell.summary?.text = trimmed.removeHTMLFromString()?.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
            let totalClips = String(123)
            cell.totalClips?.text = String(totalClips + " clips")
            
            if let pubDate = episode.pubDate {
                cell.pubDate?.text = pubDate.toShortFormatString()
            }
            
            if episode.fileName != nil {
                cell.activityIndicator.stopAnimating()
                cell.activityView.isHidden = true
                let playImage = UIImage(named: "play")
                cell.button.setImage(playImage, for: .normal)
            } else if (DownloadingEpisodeList.shared.downloadingEpisodes.contains(where: {$0.mediaUrl == episode.mediaUrl})) {
                cell.activityIndicator.startAnimating()
                cell.activityView.isHidden = false
                cell.button.setImage(nil, for: .normal)
            } else {
                cell.activityIndicator.stopAnimating()
                cell.activityView.isHidden = true
                let downloadImage = UIImage(named: "dl-cloud")
                cell.button.setImage(downloadImage, for: .normal)
            }
            
            cell.button.addTarget(self, action: #selector(downloadPlay(sender:)), for: .touchUpInside)
            
            return cell
            
        }
        
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath as IndexPath, animated: true)
        
        if self.filterTypeSelected == .clips {
            let clip = clipsArray[indexPath.row]
            let playerHistoryItem = self.playerHistoryManager.convertMediaRefToPlayerHistoryItem(mediaRef: clip)
            self.goToNowPlaying()
            self.pvMediaPlayer.loadPlayerHistoryItem(item: playerHistoryItem)
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        if self.filterTypeSelected != .clips {
            let episodeToEdit = episodesArray[indexPath.row]
            
            let deleteAction = UITableViewRowAction(style: .default, title: "Delete", handler: {action, indexpath in
                self.episodesArray.remove(at: indexPath.row)
                self.tableView.deleteRows(at: [indexPath], with: .fade)
                if self.pvMediaPlayer.nowPlayingItem?.episodeMediaUrl == episodeToEdit.mediaUrl {
                    self.tabBarController?.hidePlayerView()
                }
                
                PVDeleter.deleteEpisode(episodeId: episodeToEdit.objectID, fileOnly: true, shouldCallNotificationMethod: true)
                
                if self.filterTypeSelected == .downloaded && self.episodesArray.count < 1 {
                    self.loadNoDownloadedEpisodesMessage()
                }
            })
            
            return [deleteAction]
        } else {
            return []
        }
        
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

extension EpisodesTableViewController {
    
    func updateCellByNotification(_ notification:Notification) {
        if let downloadingEpisode = notification.userInfo?[Episode.episodeKey] as? DownloadingEpisode, let mediaUrl = downloadingEpisode.mediaUrl, let index = self.episodesArray.index(where: { $0.mediaUrl == mediaUrl }) {
            
            self.moc.refresh(self.episodesArray[index], mergeChanges: true)
            self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)            
        } else {
            reloadEpisodeData()
        }
    }
    
    func downloadFinished(_ notification:Notification) {
        updateCellByNotification(notification)
    }
    
    func downloadPaused(_ notification:Notification) {
        updateCellByNotification(notification)
    }
    
    func downloadCanceled(_ notification:Notification) {
        updateCellByNotification(notification)
    }

    func downloadResumed(_ notification:Notification) {
        updateCellByNotification(notification)
    }
    
    func downloadStarted(_ notification:Notification) {
        updateCellByNotification(notification)
    }
    
    override func episodeDeleted(_ notification:Notification) {
        super.episodeDeleted(notification)
        
        if let mediaUrl = notification.userInfo?["mediaUrl"] as? String, let index = self.episodesArray.index(where: { $0.mediaUrl == mediaUrl }), let _ = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? EpisodeTableViewCell {
            if self.filterTypeSelected == .downloaded {
                self.episodesArray.remove(at: index)
                self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                self.moc.parent?.refreshAllObjects()
                self.moc.refreshAllObjects()
            }
        }
    }

}

extension EpisodesTableViewController:UIWebViewDelegate {
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

extension EpisodesTableViewController:FilterSelectionProtocol {
    func filterButtonTapped() {
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: EpisodesFilter.downloaded.text, style: .default, handler: { action in
            self.filterTypeSelected = .downloaded
            self.reloadEpisodeData()
        }))
        
        alert.addAction(UIAlertAction(title: EpisodesFilter.allEpisodes.text, style: .default, handler: { action in
            self.filterTypeSelected = .allEpisodes
            self.reloadEpisodeData()
        }))
        
        alert.addAction(UIAlertAction(title: EpisodesFilter.clips.text, style: .default, handler: { action in
            self.filterTypeSelected = .clips
            self.retrieveClips()
        }))
        
        alert.addAction(UIAlertAction(title: EpisodesFilter.about.text, style: .default, handler: { action in
            self.filterTypeSelected = .about
            self.showAbout()
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

