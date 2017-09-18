//
//  PlaylistDetailTableViewController.swift
//  Podverse
//
//  Created by Mitchell Downey on 8/24/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

import UIKit

class PlaylistDetailTableViewController: PVViewController {
    
    var playlist: Playlist?
    var playlistId: String?
    var mediaRefsArray = [MediaRef]()
    let reachability = PVReachability.shared
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var itemCount: UILabel!
    @IBOutlet weak var lastUpdated: UILabel!
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var playlistTitle: UILabel!
    @IBOutlet weak var retryButton: UIButton!
    @IBOutlet weak var statusMessage: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    @IBAction func retryButtonTouched(_ sender: Any) {
        showIndicator()
        
        if let id = self.playlistId {
            Playlist.retrievePlaylistFromServer(id: id) { (playlist) -> Void in
                self.reloadPlaylistData(playlist: playlist)
            }
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.activityIndicator.hidesWhenStopped = true
        showIndicator()
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        
        if let id = self.playlistId {
            Playlist.retrievePlaylistFromServer(id: id) { (playlist) -> Void in
                self.reloadPlaylistData(playlist: playlist)
            }
        }

    }
    
    func reloadPlaylistData(playlist: Playlist?) {
        if self.reachability.hasInternetConnection() == false {
            self.showStatusMessage(message: "You must connect to the internet to load this playlist.")
            return
        }
        
        if let playlist = playlist {
            self.itemCount.text = "Items: " + String(playlist.mediaRefs.count)
            self.lastUpdated.text = playlist.lastUpdated?.toShortFormatString()
            self.playlistTitle.text = playlist.title
            self.mediaRefsArray = playlist.mediaRefs
        }
        
        self.showPlaylistView()
        self.tableView.reloadData()
        
    }
    
    func showStatusMessage(message: String) {
        self.activityIndicator.stopAnimating()
        self.statusMessage.text = message
        self.tableView.isHidden = true
        self.loadingView.isHidden = false
        self.statusMessage.isHidden = false

        if message == "You must connect to the internet to load this playlist." {
            self.retryButton.isHidden = false
        }
    }
    
    func showIndicator() {
        self.activityIndicator.startAnimating()
        self.tableView.isHidden = true
        self.loadingView.isHidden = false
        self.activityIndicator.isHidden = false
        self.statusMessage.isHidden = true
        self.retryButton.isHidden = true
    }
    
    func showPlaylistView() {
        self.activityIndicator.stopAnimating()
        self.tableView.isHidden = false
        self.loadingView.isHidden = true
        self.statusMessage.isHidden = true
        self.retryButton.isHidden = true
    }

}

extension PlaylistDetailTableViewController:UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.mediaRefsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let mediaRef = self.mediaRefsArray[indexPath.row]
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! PlaylistDetailTableViewCell

        cell.episodeTitle.text = mediaRef.episodeTitle
        cell.podcastTitle.text = mediaRef.podcastTitle
        cell.pubDate.text = mediaRef.episodePubDate?.toShortFormatString()
        
        cell.podcastImage.sd_setImage(with: URL(string: mediaRef.podcastImageUrl ?? ""), placeholderImage: #imageLiteral(resourceName: "PodverseIcon"))
        
        if mediaRef.isClip() {
            cell.clipTitle.text = mediaRef.readableClipTitle()
            if let time = mediaRef.readableStartAndEndTime() {
                cell.time.text = time
            }
        } else {
            cell.time.text = "--:--"
            cell.clipTitle.text = "Full Episode"
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let mediaRef = mediaRefsArray[indexPath.row]
        let playerHistoryItem = self.playerHistoryManager.convertMediaRefToPlayerHistoryItem(mediaRef: mediaRef)
        self.goToNowPlaying()
        self.pvMediaPlayer.loadPlayerHistoryItem(item: playerHistoryItem)
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let mediaRef = mediaRefsArray[indexPath.row]
        
        let deleteAction = UITableViewRowAction(style: .default, title: "Remove", handler: {action, indexpath in
            
            if self.reachability.hasInternetConnection() == false {
                self.showStatusMessage(message: "You must connect to the internet to remove playlist items.")
                return
            }
            
            if let mediaRefId = mediaRef.id, let playlistId = self.playlistId {
                self.mediaRefsArray.remove(at: indexPath.row)
                self.tableView.deleteRows(at: [indexPath], with: .fade)
                
                // TODO: how do we make the completion block optional?
                Playlist.removeFromPlaylist(playlistId: playlistId, mediaRefId: mediaRefId) {_ in }
            }
            
        })
        
        return [deleteAction]
    }
    
}
