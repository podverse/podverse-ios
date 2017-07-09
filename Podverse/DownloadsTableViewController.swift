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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        PVDownloader.shared.delegate = self
        tableView.reloadData()
    }
    
    func indexPathOfDownload(episode: DownloadingEpisode) -> IndexPath? {
        if let row = DownloadingEpisodeList.shared.downloadingEpisodes.index(where: {$0.mediaUrl == episode.mediaUrl}) {
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
        
        DispatchQueue.global().async {
            Podcast.retrievePodcastUIImage(downloadingEpisode: episode) { (podcastImage) -> Void in
                DispatchQueue.main.async {
                    cell.podcastImage.image = podcastImage
                }
            }
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

extension DownloadsTableViewController:PVDownloaderDelegate {
    func downloadFinished(episode: DownloadingEpisode) {
        if let indexPath = indexPathOfDownload(episode: episode), let cell = tableView.cellForRow(at: indexPath) as? DownloadTableViewCell {
            DispatchQueue.main.async {
                cell.progress.setProgress(1, animated: false)
                cell.progressStats.text = ""
                cell.status.text = "Finished"
            }
        }
    }
    func downloadPaused(episode: DownloadingEpisode) {
        if let indexPath = indexPathOfDownload(episode: episode) {
            DispatchQueue.main.async {
                if let cell = self.tableView.cellForRow(at: indexPath) as? DownloadTableViewCell {
                    cell.progress.setProgress(episode.progress, animated: false)
                    cell.progressStats.text = ""
                    cell.status.text = "Paused"
                }
            }
        }
    }
    func downloadProgressed(episode: DownloadingEpisode) {
        if let indexPath = indexPathOfDownload(episode: episode) {
            DispatchQueue.main.async {
                if let cell = self.tableView.cellForRow(at: indexPath) as? DownloadTableViewCell {
                    cell.progress.setProgress(episode.progress, animated: false)
                    cell.progressStats.text = episode.formattedTotalBytesDownloaded
                    cell.status.text = "Downloading"
                }
            }
        }
    }
    func downloadResumed(episode: DownloadingEpisode) {
        if let indexPath = indexPathOfDownload(episode: episode) {
            DispatchQueue.main.async {
                if let cell = self.tableView.cellForRow(at: indexPath) as? DownloadTableViewCell {
                    cell.progress.setProgress(episode.progress, animated: false)
                    cell.progressStats.text = episode.formattedTotalBytesDownloaded
                    cell.status.text = "Downloading"
                }
            }
        }
    }
    func downloadStarted() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
}
