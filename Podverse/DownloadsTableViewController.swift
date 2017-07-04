//
//  DownloadsTableViewController.swift
//  Podverse
//
//  Created by Creon on 12/15/16.
//  Copyright © 2016 Podverse LLC. All rights reserved.
//

import UIKit

class DownloadsTableViewController: PVViewController {
    
    var episodes = DownloadingEpisodeList.shared.downloadingEpisodes
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        PVDownloader.shared.delegate = self
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
        cell.status.text = "Downloading"
        
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
                }
            }
        }
    }
    func downloadStarted() {
        episodes = DownloadingEpisodeList.shared.downloadingEpisodes
        tableView.reloadData()
    }
}
