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
    @IBOutlet weak var activityIndicatorView: UIView!
    @IBOutlet weak var itemCount: UILabel!
    @IBOutlet weak var lastUpdated: UILabel!
    @IBOutlet weak var playlistTitle: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Playlist"
        
        self.activityIndicator.hidesWhenStopped = true
        
        retrievePlaylist()
        
    }
    
    func retrievePlaylist() {
        
        guard checkConnectivity() else {
            return
        }
        
        self.hideNoDataView()
        
        showActivityIndicator()
        
        if let id = self.playlistId {
            Playlist.retrievePlaylistFromServer(id: id) { (playlist) -> Void in
                self.reloadPlaylistData(playlist: playlist)
            }
        }
    }
    
    func checkConnectivity() -> Bool {
        
        let message = Strings.Errors.noPlaylistsInternet
        let buttonTitle = "Retry"
        let selector:Selector = #selector(PlaylistsTableViewController.retrievePlaylists)
        
        guard checkForConnectivity() else {
            loadNoDataView(message: message, buttonTitle: buttonTitle, buttonPressed: selector)
            return false
        }
        
        return true
    }
    
    func checkForResults(playlist: Playlist?) -> Bool {
        
        let message = Strings.Errors.noPlaylistItemsAvailable
        
        guard let playlist = playlist, playlist.mediaRefs.count > 0 else {
            loadNoDataView(message: message, buttonTitle: nil, buttonPressed: nil)
            return false
        }
        
        return true
        
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
        
        hideActivityIndicator()
        self.tableView.isHidden = true
        showNoDataView()
        
    }
    
    func reloadPlaylistData(playlist: Playlist?) {

        hideActivityIndicator()
        
        guard checkForResults(playlist: playlist), let playlist = playlist else {
            return
        }
        
        self.mediaRefsArray = playlist.mediaRefs
        
        self.tableView.isHidden = false
        self.tableView.reloadData()
        
    }
    
    func showActivityIndicator() {
        self.tableView.isHidden = true
        self.activityIndicator.startAnimating()
        self.activityIndicatorView.isHidden = false
    }
    
    func hideActivityIndicator() {
        self.activityIndicator.stopAnimating()
        self.activityIndicatorView.isHidden = true
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
        
        cell.podcastImage.image = Podcast.retrievePodcastImage(podcastImageURLString: mediaRef.podcastImageUrl, feedURLString: mediaRef.podcastFeedUrl, managedObjectID: nil, completion: { _ in
            cell.podcastImage.sd_setImage(with: URL(string: mediaRef.podcastImageUrl ?? ""), placeholderImage: #imageLiteral(resourceName: "PodverseIcon"))
        })
        
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
            
            guard checkForConnectivity() else {
                let alert = UIAlertController(title: "Internet Required", message: Strings.Errors.internetRequiredDeletePlaylistItem, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
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
