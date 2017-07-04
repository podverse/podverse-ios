import UIKit
import CoreData

class EpisodesTableViewController: PVViewController, UITableViewDataSource, UITableViewDelegate, PVFeedParserDelegate {
    
    var showAllEpisodes = false
    
    let moc = CoreDataHelper.createMOCForThread(threadType: .privateThread)
    
    var selectedPodcastID: NSManagedObjectID!
    var podcast: Podcast!
    var episodesArray = [Episode]()
    
    let reachability = PVReachability.shared
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var headerPodcastTitle: UILabel!
    
    @IBOutlet weak var headerImageView: UIImageView!
    
    func loadData() {
        podcast = CoreDataHelper.fetchEntityWithID(objectId: self.selectedPodcastID, moc: moc) as! Podcast

        episodesArray = Array(podcast.episodes)
        
        let unsortedEpisodes = NSMutableArray()
        let sortDescriptor = NSSortDescriptor(key: "pubDate", ascending: false)
        for singleEpisode in episodesArray {
            unsortedEpisodes.add(singleEpisode)
        }
        episodesArray = unsortedEpisodes.sortedArray(using: [sortDescriptor]) as! [Episode]

        tableView.reloadData()
    }

    func downloadPlay(sender: UIButton) {
        if let cell = sender.superview?.superview as? EpisodeTableViewCell,
           let indexRow = self.tableView.indexPath(for: cell)?.row {
        
            let episode = episodesArray[indexRow]
            if episode.fileName != nil {
                if pvMediaPlayer.avPlayer.rate == 1 {
                    pvMediaPlayer.saveCurrentTimeAsPlaybackPosition()
                }
                
                let playerHistoryItem = playerHistoryManager.convertEpisodeToPlayerHistoryItem(episode: episode)
                pvMediaPlayer.loadPlayerHistoryItem(playerHistoryItem: playerHistoryItem)
                
//                pvMediaPlayer.loadEpisodeDownloadedMediaFileOrStream(episodeID: episode.objectID, paused: false)
                segueToNowPlaying()
            } else {
//                if reachability.hasInternetConnection() == false {
//                    showInternetNeededAlert("Connect to WiFi or cellular data to download an episode.")
//                    return
//                }
                PVDownloader.shared.startDownloadingEpisode(episode: episode)
                cell.button.setTitle("DLing", for: .normal)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        loadData()
        
        PVDownloader.shared.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(loadData), name: NSNotification.Name(kDownloadHasFinished), object: nil)
        
        headerPodcastTitle.text = podcast.title
        
        DispatchQueue.global().async {
            var cellImage:UIImage?
            
            if let imageData = self.podcast.imageThumbData, let image = UIImage(data: imageData) {
                cellImage = image
            }
            else {
                cellImage = UIImage(named: "PodverseIcon")
            }
            
            DispatchQueue.main.async {
                self.headerImageView.image = cellImage
            }
        }
        
    }

//    // MARK: - Table view data source
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//        if showAllEpisodes == false {
//            return "Downloaded"
//        } else {
            return "All Available Episodes"
//        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return episodesArray.count + 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.row < episodesArray.count {
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
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath as IndexPath)
//
//            if showAllEpisodes == false {
//                cell.textLabel!.text = "Show All Episodes"
//                
//            } else {
//                cell.textLabel!.text = "Show Downloaded Episodes"
//            }
//            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        if indexPath.row < episodesArray.count {
            return 120
//        }
//        else {
//            return 60
//        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "To Now Playing" {
            let mediaPlayerViewController = segue.destination as! MediaPlayerViewController
            mediaPlayerViewController.shouldAutoplay = true
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // If not the last item in the array, then perform selected episode actions
        if indexPath.row < episodesArray.count {
            
            let episode = episodesArray[indexPath.row]
            
            let episodeActions = UIAlertController(title: "", message: "", preferredStyle: UIAlertControllerStyle.actionSheet)
            
            if episode.fileName != nil {
                episodeActions.addAction(UIAlertAction(title: "Play Episode", style: .default, handler: { action in
                    let playerHistoryItem = self.playerHistoryManager.convertEpisodeToPlayerHistoryItem(episode: episode)
                    self.pvMediaPlayer.loadPlayerHistoryItem(playerHistoryItem: playerHistoryItem)
                    self.segueToNowPlaying()
                }))
            } else {
//                // TODO: check if episode is in downloading array
//                if episode.taskIdentifier != nil {
//                    episodeActions.addAction(UIAlertAction(title: "Downloading Episode", style: .default, handler: nil))
//                } else {
                    episodeActions.addAction(UIAlertAction(title: "Download Episode", style: .default, handler: { action in
                        if self.reachability.hasInternetConnection() == true {
                            PVDownloader.shared.startDownloadingEpisode(episode: episode)
                            let cell = tableView.cellForRow(at: indexPath as IndexPath) as! EpisodeTableViewCell
                            //                            cell.downloadPlayButton.setTitle("DLing", forState: .Normal)
                        }
                        else {
                            //                            self.showInternetNeededAlert("Connect to WiFi or cellular data to download an episode.")
                        }
                    }))
//                }
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
                self.pvMediaPlayer.loadPlayerHistoryItem(playerHistoryItem: playerHistoryItem)
                self.segueToNowPlaying()
            }))
            
            episodeActions.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            self.present(episodeActions, animated: true, completion: nil)
        }
            // Else Show All Episodes or Show Downloaded Episodes
        else {
            //            toggleShowAllEpisodes()
        }
        
        tableView.deselectRow(at: indexPath as IndexPath, animated: true)

    }


//
//    func toggleShowAllEpisodes() {
//        let vc = self.storyboard?.instantiateViewControllerWithIdentifier("episodesTableViewController") as! EpisodesTableViewController
//        vc.selectedPodcastId = selectedPodcast.objectID
//        vc.showAllEpisodes = !showAllEpisodes
//        if showAllEpisodes == false {
//            self.navigationController?.pushViewController(vc, animated: true)
//        } else {
//            navigationController?.popViewControllerAnimated(true)
//        }
//        
//    }
//    
//    // Override to support conditional editing of the table view.
//    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
//        // Return False if you do not want the specified item to be editable.
//        if indexPath.row < episodesArray.count {
//            let episode = episodesArray[indexPath.row]
//            if episode.fileName != nil {
//                return true
//            }
//            else {
//                return false
//            }
//        }
//        else {
//            return false
//        }
//    }
//    
//    // Override to support editing the table view.
//    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
//        if editingStyle == .Delete {
//            PVDeleter.deleteEpisode(episodesArray[indexPath.row].objectID)
//            episodesArray.removeAtIndex(indexPath.row)
//            self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
//            if let podcastTableVC = self.navigationController?.viewControllers.first as? PodcastsTableViewController {
//                podcastTableVC.reloadPodcastData()
//            }
//        }
//    }
//    
//    // MARK: - Navigation
//    
//    // In a storyboard-based application, you will often want to do a little preparation before navigation
//    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
//        if segue.identifier == Constants.TO_PLAYER_SEGUE_ID {
//            let mediaPlayerViewController = segue.destinationViewController as! MediaPlayerViewController
//            mediaPlayerViewController.hidesBottomBarWhenPushed = true
//        } else if segue.identifier == "Show Clips" {
//            let clipsTableViewController = segue.destinationViewController as! ClipsTableViewController
//            clipsTableViewController.selectedPodcast = selectedPodcast
//            clipsTableViewController.selectedEpisode = selectedEpisode
//        }
//    }
//    
// TODO Why does this need feedUrl twice?
    func feedParsingComplete(feedUrl feedUrl:String?) {
//        TODO
//        self.refreshControl.endRefreshing()
//        tableView.reloadData()
    }
}

extension EpisodesTableViewController:PVDownloaderDelegate {
    func downloadFinished(episode: DownloadingEpisode) {
        print("oh hai")
    }
    func downloadProgressed(episode: DownloadingEpisode) {
        print("y tho")
    }
    func downloadStarted() {
        print("no wai")
    }
}
