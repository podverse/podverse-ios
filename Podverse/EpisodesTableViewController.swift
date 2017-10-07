import UIKit
import CoreData

protocol AutoDownloadProtocol: NSObjectProtocol {
    func podcastAutodownloadChanged(feedUrl: String)
}

class EpisodesTableViewController: PVViewController, UITableViewDataSource, UITableViewDelegate {
    
    weak var delegate: AutoDownloadProtocol?
    var episodesArray = [Episode]()
    let moc = CoreDataHelper.createMOCForThread(threadType: .privateThread)
    let reachability = PVReachability.shared
    var feedUrl: String?
    
    var filterTypeSelected: EpisodesFilter = .downloaded {
        didSet {
            self.filterType.setTitle(filterTypeSelected.text + "\u{2304}", for: .normal)
        }
    }
    
    @IBOutlet weak var autoDownloadLabel: UILabel!
    @IBOutlet weak var autoDownloadSwitch: UISwitch!
    @IBOutlet weak var bottomButton: UITableView!
    @IBOutlet weak var headerImageView: UIImageView!
    @IBOutlet weak var headerPodcastTitle: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var filterType: UIButton!
    @IBOutlet weak var sorting: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.filterTypeSelected = .downloaded
        loadData()
        setupNotificationListeners()
    }
    
    deinit {
        removeObservers()
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
    
    @IBAction func updateFilter(_ sender: Any) {
        
        let alert = UIAlertController(title: "Show", message: nil, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Downloaded", style: .default, handler: { action in
            self.filterTypeSelected = .downloaded
            self.loadData()
        }))
        
        alert.addAction(UIAlertAction(title: "All Episodes", style: .default, handler: { action in
            self.filterTypeSelected = .allEpisodes
            self.loadData()
        }))
        
        alert.addAction(UIAlertAction(title: "Clips", style: .default, handler: { action in
            self.filterTypeSelected = .clips
            self.loadData()
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    
    @IBAction func updateSorting(_ sender: Any) {
    }
    
    func loadData() {
        
        if let feedUrl = feedUrl, let podcast = Podcast.podcastForFeedUrl(feedUrlString: feedUrl, managedObjectContext: moc) {
            
            episodesArray.removeAll()
            
            headerPodcastTitle.text = podcast.title
            
            self.headerImageView.image = Podcast.retrievePodcastImage(podcastImageURLString: podcast.imageUrl, feedURLString: podcast.feedUrl, managedObjectID: podcast.objectID, completion: { _ in
                self.headerImageView.sd_setImage(with: URL(string: podcast.imageUrl ?? ""), placeholderImage: #imageLiteral(resourceName: "PodverseIcon"))
            })
            
            self.autoDownloadSwitch.isOn = podcast.shouldAutoDownload() ? true : false
            
            if self.filterTypeSelected == .downloaded {
                episodesArray = Array(podcast.episodes.filter { $0.fileName != nil } )
                let downloadingEpisodes = DownloadingEpisodeList.shared.downloadingEpisodes.filter({$0.podcastFeedUrl == podcast.feedUrl})

                for dlEpisode in downloadingEpisodes {
                    if let mediaUrl = dlEpisode.mediaUrl, let episode = Episode.episodeForMediaUrl(mediaUrlString: mediaUrl, managedObjectContext: self.moc), !episodesArray.contains(episode) {
                        episodesArray.append(episode)
                    }
                }
            } else if self.filterTypeSelected == .allEpisodes {
                episodesArray = Array(podcast.episodes)
            } else if self.filterTypeSelected == .clips {
                print("clips filter selected")
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
                    showInternetNeededAlertWithDesciription(message: "Connect to WiFi to download an episode.")
                    return
                }
                PVDownloader.shared.startDownloadingEpisode(episode: episode)
            }
        }
    }

//    // MARK: - Table view data source
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return episodesArray.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath as IndexPath) as! EpisodeTableViewCell

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
        
        if (DownloadingEpisodeList.shared.downloadingEpisodes.contains(where: {$0.mediaUrl == episode.mediaUrl})) {
            cell.button.setTitle("DLing", for: .normal)
        } else if episode.fileName != nil {
            cell.button.setTitle("Play", for: .normal)
        } else {
            cell.button.setTitle("DL", for: .normal)
        }

        cell.button.addTarget(self, action: #selector(downloadPlay(sender:)), for: .touchUpInside)

        return cell
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    override func goToNowPlaying () {
        if let mediaPlayerVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MediaPlayerVC") as? MediaPlayerViewController {
            pvMediaPlayer.shouldAutoplayOnce = true
            self.navigationController?.pushViewController(mediaPlayerVC, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath as IndexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let episodeToEdit = episodesArray[indexPath.row]
        
        let deleteAction = UITableViewRowAction(style: .default, title: "Delete", handler: {action, indexpath in
            self.episodesArray.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .fade)
            if self.pvMediaPlayer.nowPlayingItem?.episodeMediaUrl == episodeToEdit.mediaUrl {
                self.tabBarController?.hidePlayerView()
            }

            PVDeleter.deleteEpisode(episodeId: episodeToEdit.objectID, fileOnly: true, shouldCallNotificationMethod: true)
        })
        
        return [deleteAction]
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

extension EpisodesTableViewController {
    
    func updateCellByNotification(_ notification:Notification) {
        loadData()
        if let downloadingEpisode = notification.userInfo?[Episode.episodeKey] as? DownloadingEpisode, let mediaUrl = downloadingEpisode.mediaUrl, let index = self.episodesArray.index(where: { $0.mediaUrl == mediaUrl }) {
            
            self.moc.refresh(self.episodesArray[index], mergeChanges: true)
            self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)            
        }
    }
    
    func downloadFinished(_ notification:Notification) {
        updateCellByNotification(notification)
    }
    
    func downloadPaused(_ notification:Notification) {
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
                self.moc.refreshAllObjects()
            }
        }
    }

}
