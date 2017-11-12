//
//  DownloadsTableViewController.swift
//  Podverse
//
//  Created by Creon on 12/15/16.
//  Copyright © 2016 Podverse LLC. All rights reserved.
//

import UIKit

class DownloadsTableViewController: PVViewController {
    let pvDownloader = PVDownloader.shared
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Downloads"
        
        setupNotificationListeners()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    deinit {
        removeObservers()
    }
    
    func indexPathOfDownload(mediaUrl: String?) -> IndexPath? {
        if let row = DownloadingEpisodeList.shared.downloadingEpisodes.index(where: {$0.mediaUrl == mediaUrl}) {
            return IndexPath(row: row, section: 0)
        }
        return nil
    }
    
    override func goToNowPlaying () {
        if let mediaPlayerVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MediaPlayerVC") as? MediaPlayerViewController {
            pvMediaPlayer.shouldAutoplayOnce = true
            self.navigationController?.pushViewController(mediaPlayerVC, animated: true)
        }
    }
    
    fileprivate func setupNotificationListeners() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.downloadStarted), name: .downloadStarted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.downloadProgressed(_:)), name: .downloadProgressed, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.downloadResumed(_:)), name: .downloadResumed, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.downloadPaused(_:)), name: .downloadPaused, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.downloadFinished(_:)), name: .downloadFinished, object: nil)
    }
    
    fileprivate func removeObservers() {
        NotificationCenter.default.removeObserver(self, name: .downloadStarted, object: nil)
        NotificationCenter.default.removeObserver(self, name: .downloadResumed, object: nil)
        NotificationCenter.default.removeObserver(self, name: .downloadPaused, object: nil)
        NotificationCenter.default.removeObserver(self, name: .downloadFinished, object: nil)
        NotificationCenter.default.removeObserver(self, name: .downloadProgressed, object: nil)
    }
}

extension DownloadsTableViewController:UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 96.5
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return DownloadingEpisodeList.shared.downloadingEpisodes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! DownloadTableViewCell
        
        let episode = DownloadingEpisodeList.shared.downloadingEpisodes[indexPath.row]
        
        cell.podcastImage.image = Podcast.retrievePodcastImage(podcastImageURLString: episode.podcastImageUrl, feedURLString: episode.podcastFeedUrl, managedObjectID: nil, completion: { _ in
            cell.podcastImage.sd_setImage(with: URL(string: episode.podcastImageUrl ?? ""), placeholderImage: #imageLiteral(resourceName: "PodverseIcon"))
        })
        
        cell.episodeTitle.text = episode.title
        cell.podcastTitle.text = episode.podcastTitle
        
        if episode.downloadComplete == true {
            cell.status.text = "Finished"
            cell.progress.setProgress(1.0, animated: false)
        } else if episode.taskResumeData != nil {
            cell.status.text = "Paused"
        } else {
            cell.status.text = "Downloading"
        }
        
        cell.progressStats.text = ""
        
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let downloadingEpisode = DownloadingEpisodeList.shared.downloadingEpisodes[indexPath.row]
        
        if downloadingEpisode.taskResumeData != nil {
            pvDownloader.resumeDownloadingEpisode(downloadingEpisode: downloadingEpisode)
        } else if downloadingEpisode.downloadComplete == true {
            let moc = CoreDataHelper.createMOCForThread(threadType: .mainThread)
            if let mediaUrl = downloadingEpisode.mediaUrl {
                let episode = CoreDataHelper.retrieveExistingOrCreateNewEpisode(mediaUrlString: mediaUrl, moc: moc)
                let playerHistoryItem = playerHistoryManager.convertEpisodeToPlayerHistoryItem(episode: episode)
                pvMediaPlayer.loadPlayerHistoryItem(item: playerHistoryItem)
                goToNowPlaying()
            }
        } else {
            pvDownloader.pauseDownloadingEpisode(downloadingEpisode: downloadingEpisode)
        }
        
        tableView.deselectRow(at: indexPath, animated: false)

    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let episodeToEdit = DownloadingEpisodeList.shared.downloadingEpisodes[indexPath.row]
        
        let action:UITableViewRowAction
        
        if let downloadComplete = episodeToEdit.downloadComplete, downloadComplete == true {
            action = UITableViewRowAction(style: .default, title: "Hide", handler: {action, indexpath in
                DownloadingEpisodeList.removeDownloadingEpisodeWithMediaURL(mediaUrl: episodeToEdit.mediaUrl)
                self.tableView.deleteRows(at: [indexPath], with: .fade)
            })
        } else {
            action = UITableViewRowAction(style: .default, title: "Cancel", handler: {action, indexpath in
                self.pvDownloader.cancelDownloadingEpisode(downloadingEpisode: episodeToEdit)
                self.tableView.deleteRows(at: [indexPath], with: .fade)
            })
        }
        
        return [action]
    }
}

extension DownloadsTableViewController {
    func downloadFinished(_ notification:Notification) {
        if let episode = notification.userInfo?[Episode.episodeKey] as? DownloadingEpisode, 
           let indexPath = indexPathOfDownload(mediaUrl: episode.mediaUrl),
           let cell = tableView.cellForRow(at: indexPath) as? DownloadTableViewCell {
            cell.progress.setProgress(1, animated: false)
            cell.progressStats.text = ""
            cell.status.text = "Finished"
        }
    }
    
    func downloadPaused(_ notification:Notification) {
        if let episode = notification.userInfo?[Episode.episodeKey] as? DownloadingEpisode, 
           let indexPath = indexPathOfDownload(mediaUrl: episode.mediaUrl),
           let cell = self.tableView.cellForRow(at: indexPath) as? DownloadTableViewCell {
            cell.progress.setProgress(episode.progress, animated: false)
            cell.progressStats.text = ""
            cell.status.text = "Paused"
        }
    }
    
    func downloadProgressed(_ notification:Notification) {
        if let episode = notification.userInfo?[Episode.episodeKey] as? DownloadingEpisode, 
           let indexPath = indexPathOfDownload(mediaUrl: episode.mediaUrl),
           let cell = self.tableView.cellForRow(at: indexPath) as? DownloadTableViewCell {
            cell.progress.setProgress(episode.progress, animated: false)
            cell.progressStats.text = episode.formattedTotalBytesDownloaded
            cell.status.text = "Downloading"
        }
    }
    func downloadResumed(_ notification:Notification) {
        if let episode = notification.userInfo?[Episode.episodeKey] as? DownloadingEpisode, 
           let indexPath = indexPathOfDownload(mediaUrl: episode.mediaUrl),
           let cell = self.tableView.cellForRow(at: indexPath) as? DownloadTableViewCell {
            cell.progress.setProgress(episode.progress, animated: false)
            cell.progressStats.text = episode.formattedTotalBytesDownloaded
            cell.status.text = "Downloading"
        }
    }
    
    func downloadStarted() {
        self.tableView.reloadData()
    }
    
    override func episodeDeleted(_ notification:Notification) {
        super.episodeDeleted(notification)
        if let mediaUrl = notification.userInfo?["mediaUrl"] as? String, let indexPath = indexPathOfDownload(mediaUrl: mediaUrl) {
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
}
