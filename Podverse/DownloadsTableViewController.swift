//
//  DownloadsTableViewController.swift
//  Podverse
//
//  Created by Creon on 12/15/16.
//  Copyright © 2016 Podverse LLC. All rights reserved.
//

import UIKit

class DownloadsTableViewController: PVViewController {
    var episodes = [DownloadingEpisode]()
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        PVDownloader.shared.delegate = self
        episodes = DownloadingEpisodeList.shared.downloadingEpisodes
        tableView.reloadData()
    }
    
    func indexPathOfDownload(episode: DownloadingEpisode) -> IndexPath? {
        if let row = episodes.index(where: {$0 === episode}) {
            return IndexPath(row: row, section: 0)
        }
        return nil
    }

}

extension DownloadsTableViewController:UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 92
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return episodes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! DownloadTableViewCell
        
        let episode = episodes[indexPath.row]
        
        DispatchQueue.global().async {
            Podcast.retrievePodcastUIImage(downloadingEpisode: episode) { (podcastImage) -> Void in
                DispatchQueue.main.async {
                    DispatchQueue.main.async {
                        cell.podcastImage.image = podcastImage
                    }
                }
            }
        }
        
        cell.episodeTitle.text = episode.title
        cell.podcastTitle.text = episode.podcastTitle
        
        if episode.downloadComplete == true {
            cell.status.text = "Finished"
        } else if episode.taskResumeData != nil {
            cell.status.text = "Paused"
        } else {
            cell.status.text = "Downloading"
        }
        
        cell.progressStats.text = ""
        cell.progress.setProgress(0, animated: false)
        
        return cell
        
    }
    
}

extension DownloadsTableViewController:PVDownloaderDelegate {
    func downloadFinished(episode: DownloadingEpisode) {
        if let indexPath = indexPathOfDownload(episode: episode) {
            if let cell = tableView.cellForRow(at: indexPath) as? DownloadTableViewCell {
                DispatchQueue.main.async {
                    cell.progress.setProgress(1, animated: false)
                    cell.progressStats.text = ""
                    cell.status.text = "Finished"
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
    func downloadStarted() {
        episodes = DownloadingEpisodeList.shared.downloadingEpisodes
        tableView.reloadData()
    }
}
