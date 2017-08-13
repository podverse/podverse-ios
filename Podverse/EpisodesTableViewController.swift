import UIKit
import CoreData

class EpisodesTableViewController: PVViewController, UITableViewDataSource, UITableViewDelegate {
    
    var showAllEpisodes = false
    
    let moc = CoreDataHelper.createMOCForThread(threadType: .privateThread)
    
    var selectedPodcastID: NSManagedObjectID!
    
    var episodesArray = [Episode]()
    
    let reachability = PVReachability.shared
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var headerPodcastTitle: UILabel!
    
    @IBOutlet weak var headerImageView: UIImageView!
    
    @IBOutlet weak var bottomButton: UITableView!
    
    @IBAction func bottomButtonTouched(_ sender: Any) {
        showAllEpisodes = !showAllEpisodes
        loadData()
        self.tableView.reloadData()
    }
    
    func loadData() {
        if let podcast = CoreDataHelper.fetchEntityWithID(objectId: self.selectedPodcastID, moc: moc) as? Podcast {
            episodesArray.removeAll()
            
            headerPodcastTitle.text = podcast.title
            
            DispatchQueue.global().async {
                var cellImage:UIImage?
                
                if let imageData = podcast.imageThumbData, let image = UIImage(data: imageData) {
                    cellImage = image
                }
                else {
                    cellImage = UIImage(named: "PodverseIcon")
                }
                
                DispatchQueue.main.async {
                    self.headerImageView.image = cellImage
                }
            }
            
            if (!showAllEpisodes) {
                episodesArray = Array(podcast.episodes.filter { $0.fileName != nil } )
            } else {
                episodesArray = Array(podcast.episodes)
            }
            episodesArray.sort(by: { (prevEp, nextEp) -> Bool in
                if let prevTimeInterval = prevEp.pubDate, let nextTimeInterval = nextEp.pubDate {
                    return (prevTimeInterval > nextTimeInterval)
                }
                
                return false
            })
        }
    }

    func downloadPlay(sender: UIButton) {
        if let cell = sender.superview?.superview as? EpisodeTableViewCell,
           let indexRow = self.tableView.indexPath(for: cell)?.row {
        
            let episode = episodesArray[indexRow]
            if episode.fileName != nil {                
                let playerHistoryItem = playerHistoryManager.convertEpisodeToPlayerHistoryItem(episode: episode)
                goToNowPlaying()
                pvMediaPlayer.loadPlayerHistoryItem(item: playerHistoryItem, startTime: nil)
            } else {
//                if reachability.hasInternetConnection() == false {
//                    showInternetNeededAlert("Connect to WiFi or cellular data to download an episode.")
//                    return
//                }
                PVDownloader.shared.startDownloadingEpisode(episode: episode)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        loadData()
        self.tableView.reloadData()
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

//    // MARK: - Table view data source
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if showAllEpisodes {
            return "All Available Episodes"
        } else {
            return "Downloaded"
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return episodesArray.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath as IndexPath) as! EpisodeTableViewCell

        let episode = episodesArray[indexPath.row]

        cell.title?.text = episode.title

        if let summary = episode.summary {
            cell.summary?.text = summary.removeHTMLFromString()
        }

        let totalClips = String(123)
        cell.totalClips?.text = String(totalClips + " clips")
 
        if let pubDate = episode.pubDate {
            cell.pubDate?.text = pubDate.toShortFormatString()
        }
        
        if episode.fileName != nil {
            cell.button.setTitle("Play", for: .normal)
        } else if (DownloadingEpisodeList.shared.downloadingEpisodes.contains(where: {$0.mediaUrl == episode.mediaUrl})) {
            cell.button.setTitle("DLing", for: .normal)
        } else {
            cell.button.setTitle("DL", for: .normal)
        }

        cell.button.addTarget(self, action: #selector(downloadPlay(sender:)), for: .touchUpInside)

        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }

    override func goToNowPlaying (timeOffset: Int64 = 0) {
        if let mediaPlayerVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MediaPlayerVC") as? MediaPlayerViewController {
            pvMediaPlayer.shouldAutoplayOnce = true
            self.navigationController?.pushViewController(mediaPlayerVC, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let episode = episodesArray[indexPath.row]
        
        let episodeActions = UIAlertController(title: "", message: "", preferredStyle: UIAlertControllerStyle.actionSheet)
        
        if episode.fileName != nil {
            episodeActions.addAction(UIAlertAction(title: "Play Episode", style: .default, handler: { action in
                let playerHistoryItem = self.playerHistoryManager.convertEpisodeToPlayerHistoryItem(episode: episode)
                self.goToNowPlaying()
                self.pvMediaPlayer.loadPlayerHistoryItem(item: playerHistoryItem)
            }))
        } else {
            episodeActions.addAction(UIAlertAction(title: "Download Episode", style: .default, handler: { action in
                if self.reachability.hasInternetConnection() == true {
                    PVDownloader.shared.startDownloadingEpisode(episode: episode)
                    let cell = tableView.cellForRow(at: indexPath as IndexPath) as! EpisodeTableViewCell
                }
            }))
        }
        
        let totalClips = String(000)
        episodeActions.addAction(UIAlertAction(title: "Show Clips (\(totalClips))", style: .default, handler: { action in
            self.performSegue(withIdentifier: "Show Clips", sender: self)
        }))
        
        episodeActions.addAction(UIAlertAction (title: "Episode Info", style: .default, handler: nil))
        
        episodeActions.addAction(UIAlertAction (title: "Stream Episode", style: .default, handler: { action in
            if self.reachability.hasInternetConnection() == false {
                //                    self.showInternetNeededAlert("Connect to WiFi or cellular data to stream an episode.")
                return
            }
            let playerHistoryItem = self.playerHistoryManager.convertEpisodeToPlayerHistoryItem(episode: episode)
            self.goToNowPlaying()
            self.pvMediaPlayer.loadPlayerHistoryItem(item: playerHistoryItem)
        }))
        
        episodeActions.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(episodeActions, animated: true, completion: nil)
    
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
            if showAllEpisodes == false {
                self.episodesArray.remove(at: index)
                self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                self.moc.refreshAllObjects()
            }
        }
    }

}
