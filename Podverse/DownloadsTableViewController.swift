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
            mediaPlayerVC.shouldAutoplay = true
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
        return 92
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return DownloadingEpisodeList.shared.downloadingEpisodes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! DownloadTableViewCell
        
        let episode = DownloadingEpisodeList.shared.downloadingEpisodes[indexPath.row]
        
        cell.podcastImage.image = Podcast.retrievePodcastImage(podcastImageURLString: episode.podcastImageUrl, feedURLString: episode.podcastFeedUrl) { (podcastImage) -> Void in
                cell.podcastImage.image = podcastImage
        }
        
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
                pvMediaPlayer.loadPlayerHistoryItem(playerHistoryItem: playerHistoryItem)
                goToNowPlaying()
            }
        } else {
            pvDownloader.pauseDownloadingEpisode(downloadingEpisode: downloadingEpisode)
        }
        
        tableView.deselectRow(at: indexPath, animated: false)

    }
}

extension DownloadsTableViewController {
    func downloadFinished(_ notification:Notification) {
        if let episode = notification.userInfo?["episode"] as? DownloadingEpisode, 
           let indexPath = indexPathOfDownload(mediaUrl: episode.mediaUrl),
           let cell = tableView.cellForRow(at: indexPath) as? DownloadTableViewCell {
            cell.progress.setProgress(1, animated: false)
            cell.progressStats.text = ""
            cell.status.text = "Finished"
        }
    }
    
    func downloadPaused(_ notification:Notification) {
        if let episode = notification.userInfo?["episode"] as? DownloadingEpisode, 
           let indexPath = indexPathOfDownload(mediaUrl: episode.mediaUrl),
           let cell = self.tableView.cellForRow(at: indexPath) as? DownloadTableViewCell {
            cell.progress.setProgress(episode.progress, animated: false)
            cell.progressStats.text = ""
            cell.status.text = "Paused"
        }
    }
    
    func downloadProgressed(_ notification:Notification) {
        if let episode = notification.userInfo?["episode"] as? DownloadingEpisode, 
           let indexPath = indexPathOfDownload(mediaUrl: episode.mediaUrl),
           let cell = self.tableView.cellForRow(at: indexPath) as? DownloadTableViewCell {
            cell.progress.setProgress(episode.progress, animated: false)
            cell.progressStats.text = episode.formattedTotalBytesDownloaded
            cell.status.text = "Downloading"
        }
    }
    func downloadResumed(_ notification:Notification) {
        if let episode = notification.userInfo?["episode"] as? DownloadingEpisode, 
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
