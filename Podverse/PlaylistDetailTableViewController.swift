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
    var ownerId: String?
    var mediaRefsArray = [MediaRef]()
    let reachability = PVReachability.shared
    var isDataAvailable = true
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var activityIndicatorView: UIView!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var itemCount: UILabel!
    @IBOutlet weak var lastUpdated: UILabel!
    @IBOutlet weak var playlistTitle: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var titleEditTextField: UITextField!
    @IBOutlet weak var titleEditView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Playlist"
        
        self.activityIndicator.hidesWhenStopped = true
        
        setupNavigationItems()
        
        self.headerView.isHidden = true
        self.titleEditView.isHidden = true

        retrievePlaylist()
    }
    
    func setupNavigationItems() {
        let share = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.action, target: self, action: #selector(showShareMenu))
        
        if let userId = UserDefaults.standard.string(forKey: "userId"), userId == self.ownerId || userId == self.playlist?.ownerId {
            let edit = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.edit, target: self, action: #selector(self.startEditPlaylist))
            self.navigationItem.rightBarButtonItems = [share, edit]
        } else if isDataAvailable, let _ = UserDefaults.standard.string(forKey: "userId") {
            let subscribe = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.bookmarks, target: self, action: #selector(self.subscribeToPlaylist))
            self.navigationItem.rightBarButtonItems = [share, subscribe]
        } else if isDataAvailable {
            self.navigationItem.rightBarButtonItems = [share]
        }
    }
    
    @objc func startEditPlaylist() {
        self.titleEditTextField.text = self.playlist?.title
        self.headerView.isHidden = true
        self.titleEditView.isHidden = false
        self.tableView.isEditing = true
        
        let cancel = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.cancel, target: self, action: #selector(self.stopEditPlaylist))
        let save = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.save, target: self, action: #selector(self.savePlaylist))
        self.navigationItem.rightBarButtonItems = [save, cancel]
    }
    
    @objc func stopEditPlaylist() {
        self.headerView.isHidden = false
        self.titleEditView.isHidden = true
        self.tableView.isEditing = false
        setupNavigationItems()
    }
    
    @objc func savePlaylist() {
        if let playlist = self.playlist, let id = playlist.id {
            
            var itemsOrder:[String] = []
            
            for mediaRef in self.mediaRefsArray {
                if let id = mediaRef.id {
                    itemsOrder.append(id)
                }
            }
            
            Playlist.updatePlaylistOnServer(id: id, title: self.titleEditTextField.text, itemsOrder: itemsOrder) { wasSuccessful in
                DispatchQueue.main.async {
                    if wasSuccessful {
                        let actions = UIAlertController(title: "Playlist updated successfully", message: nil, preferredStyle: .alert)
                        actions.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                        self.present(actions, animated: true, completion: nil)
                        self.stopEditPlaylist()
                    } else {
                        let actions = UIAlertController(title: "Failed to update playlist", message: "Please check your internet connection and try again.", preferredStyle: .alert)
                        actions.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                        self.present(actions, animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
    @objc func subscribeToPlaylist() {
        if let playlist = self.playlist, let id = playlist.id {
            Playlist.subscribeToPlaylistOnServer(id: id) { wasSuccessful in
                DispatchQueue.main.async {
                    if wasSuccessful {
                        let actions = UIAlertController(title: "Subscribed to playlist",
                                                        message: nil,
                                                        preferredStyle: .alert)
                        actions.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                        self.present(actions, animated: true, completion: nil)
                    } else {
                        let actions = UIAlertController(title: "Failed to subscribe to playlist", message: "Please check your internet connection and try again.", preferredStyle: .alert)
                        actions.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                        self.present(actions, animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
    func retrievePlaylist() {
        guard checkConnectivity() else {
            return
        }
        
        self.hideNoDataView()
        
        showActivityIndicator()
        
        if let id = self.playlistId {
            Playlist.retrievePlaylistFromServer(id: id) { (playlist) -> Void in
                self.playlist = playlist
                DispatchQueue.main.async {
                    self.reloadPlaylistData(playlist: playlist)                    
                }
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
        
        DispatchQueue.main.async {
            if let noDataView = self.view.subviews.first(where: { $0.tag == kNoDataViewTag}) {
                
                if let messageView = noDataView.subviews.first(where: {$0 is UILabel}), let messageLabel = messageView as? UILabel {
                    messageLabel.text = message
                }
                
                if let buttonView = noDataView.subviews.first(where: {$0 is UIButton}), let button = buttonView as? UIButton {
                    button.setTitle(buttonTitle, for: .normal)
                    button.setTitleColor(.blue, for: .normal)
                }
                
            }
            else {
                self.addNoDataViewWithMessage(message, buttonTitle: buttonTitle, buttonImage: nil, retryPressed: buttonPressed)
            }
            
            self.hideActivityIndicator()
            self.tableView.isHidden = true
            self.showNoDataView()
            
        }
    }
    
    func loadPlaylistHeader(playlist: Playlist?) {
        guard let playlist = playlist else {
            self.playlistTitle.text = ""
            self.itemCount.text = ""
            self.lastUpdated.text = ""
            return
        }
        
        DispatchQueue.main.async {
            self.playlistTitle.text = playlist.title
            self.itemCount.text = "Items: " + String(playlist.mediaRefs.count)
            self.lastUpdated.text = playlist.lastUpdated?.toShortFormatString()
            self.headerView.isHidden = false
        }
    }
    
    func reloadPlaylistData(playlist: Playlist?) {
        
        hideActivityIndicator()
        
        self.isDataAvailable = true
        self.setupNavigationItems()

        let hasResults = checkForResults(playlist: playlist)
        
        
        guard hasResults, let playlist = playlist else {
            return
        }
        
        loadPlaylistHeader(playlist: playlist)
        
        let sortedMediaRefs = sortMediaRefs(playlist: playlist)
        
        self.mediaRefsArray = sortedMediaRefs
        
        self.tableView.isHidden = false
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func sortMediaRefs(playlist: Playlist?) -> [MediaRef] {
        var sortedMediaRefs:[MediaRef] = []

        if let playlist = playlist {
            var unsortedMediaRefs = playlist.mediaRefs
            
            if playlist.itemsOrder.count > 0 {
                for itemId in playlist.itemsOrder {
                    guard let mediaRef = unsortedMediaRefs.first(where: { $0.id == itemId }) else {
                        continue
                    }
                    sortedMediaRefs.append(mediaRef)
                    unsortedMediaRefs = unsortedMediaRefs.filter { $0.id != itemId }
                }
            }
            
            sortedMediaRefs.append(contentsOf: unsortedMediaRefs)
        }
        
        return sortedMediaRefs
    }
    
    @objc func showShareMenu() {
        
        if let playlistId = self.playlistId {
            let playlistUrlItem = [BASE_URL + "playlists/" + playlistId]
            let activityVC = UIActivityViewController(activityItems: playlistUrlItem, applicationActivities: nil)
            activityVC.popoverPresentationController?.sourceView = self.view
            
            activityVC.completionWithItemsHandler = { activityType, success, items, error in
                if activityType == UIActivityType.copyToPasteboard {
                    self.showToast(message: kLinkCopiedToast)
                }
            }
            
            self.present(activityVC, animated: true, completion: nil)
            
        }
        
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
        
        cell.podcastImage.image = Podcast.retrievePodcastImage(podcastImageURLString: mediaRef.podcastImageUrl, feedURLString: mediaRef.podcastFeedUrl, completion: { image in
            cell.podcastImage.image = image
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
                
                self.loadPlaylistHeader(playlist: self.playlist)
                
                Playlist.removeFromPlaylist(playlistId: playlistId, mediaRefId: mediaRefId) {_ in
                    DispatchQueue.main.async {
                        self.itemCount.text = "Items: " + String(self.mediaRefsArray.count)
                    }
                }
            }
            
        })
        
        return [deleteAction]
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let movedObject = self.mediaRefsArray[sourceIndexPath.row]
        self.mediaRefsArray.remove(at: sourceIndexPath.row)
        self.mediaRefsArray.insert(movedObject, at: destinationIndexPath.row)
    }
    
}
