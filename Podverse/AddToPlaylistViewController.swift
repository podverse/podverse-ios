//
//  AddToPlaylistViewController.swift
//  Podverse
//
//  Created by Mitchell Downey on 8/26/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

import UIKit

class AddToPlaylistViewController: UIViewController {

    var allPlaylistsArray = [Playlist]()
    var filteredPlaylistsArray = [Playlist]()
    var playerHistoryItem: PlayerHistoryItem?
    let reachability = PVReachability.shared
    var shouldSaveFullEpisode = false
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var activityIndicatorView: UIView!
    @IBOutlet weak var clipTitle: UILabel!
    @IBOutlet weak var episodePubDate: UILabel!
    @IBOutlet weak var episodeTitle: UILabel!
    @IBOutlet weak var podcastImage: UIImageView!
    @IBOutlet weak var podcastTitle: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var time: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let item = playerHistoryItem {
            
            self.podcastTitle.text = item.podcastTitle?.stringByDecodingHTMLEntities()
            self.episodeTitle.text = item.episodeTitle?.stringByDecodingHTMLEntities()
            
            if shouldSaveFullEpisode {
                self.clipTitle.text = "Full Episode"
                
                if let duration = item.episodeDuration {
                    self.time.text = duration.toDurationString()
                }
                
            } else {
                self.clipTitle.text = item.clipTitle
                
                if let time = item.readableStartAndEndTime() {
                    self.time.text = time
                }
            }
                        
            if let episodePubDate = item.episodePubDate {
                self.episodePubDate.text = episodePubDate.toShortFormatString()
            }
            
            self.podcastImage.image = Podcast.retrievePodcastImage(podcastImageURLString: item.podcastImageUrl, feedURLString: item.podcastFeedUrl, completion: { image in
                self.podcastImage.image = image
            })
            
        }
        
        self.tableView.isHidden = true
        
        self.activityIndicator.hidesWhenStopped = true
        showActivityIndicator()
        
        let new = UIBarButtonItem(title: "New", style: .plain, target: self, action: #selector(showCreatePlaylist))
        self.navigationItem.rightBarButtonItem = new
        
        retrievePlaylists()
    }
    
    @objc func retrievePlaylists() {
        
        guard checkConnectivity(), checkForAuthorization() else {
            return
        }
        
        self.hideNoDataView()
        
        showActivityIndicator()
        
        Playlist.retrievePlaylistsFromServer() { (playlists) -> Void in
            self.allPlaylistsArray = playlists
            self.reloadPlaylistData()
        }
        
    }
    
    func filterPlaylists() {
        self.filteredPlaylistsArray.removeAll()
        
        for playlist in self.allPlaylistsArray {
            if playlist.ownerId == UserDefaults.standard.string(forKey: "userId") {
                self.filteredPlaylistsArray.append(playlist)
            }
        }
    }
    
    @objc func showCreatePlaylist() {
        
        if !checkForConnectivity() {
            loadNoInternetMessage()
            return
        }

        let createPlaylist = UIAlertController(title: "New Playlist", message: "Playlists are visible to anyone with link.", preferredStyle: UIAlertControllerStyle.alert)
        
        createPlaylist.addTextField(configurationHandler: {(textField: UITextField!) in
            textField.placeholder = "Title of playlist"
        })
        
        createPlaylist.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        
        createPlaylist.addAction(UIAlertAction(title: "Add", style: .default, handler: { (action: UIAlertAction!) in
            if let textField = createPlaylist.textFields?[0], let text = textField.text {
                Playlist.createPlaylist(title: text) { playlist in
                    if let playlist = playlist {
                        self.filteredPlaylistsArray.append(playlist)
                        self.tableView.reloadData()
                        self.tableView.isHidden = false
                    }
                }
            }
        }))
        
        self.present(createPlaylist, animated: true, completion: nil)
        
    }
    
    @objc func reloadPlaylistData() {
        self.filterPlaylists()
        hideActivityIndicator()
        self.tableView.isHidden = false
        self.tableView.reloadData()
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
    
    func checkForAuthorization() -> Bool {
        
        let message = Strings.Errors.noPlaylistsNotLoggedIn
        let buttonTitle = "Login"
        let selector = #selector(PlaylistsTableViewController.presentLogin)
        
        guard PVAuth.userIsLoggedIn else {
            loadNoDataView(message: message, buttonTitle: buttonTitle, buttonPressed: selector)
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
                button.setTitleColor(.blue, for: .normal)
            }
        }
        else {
            self.addNoDataViewWithMessage(message, buttonTitle: buttonTitle, buttonImage: nil, retryPressed: buttonPressed)
        }
        
        showNoDataView()
        
    }
    
    func loadNoInternetMessage() {
        loadNoDataView(message: Strings.Errors.noPlaylistsInternet, buttonTitle: "Retry", buttonPressed: #selector(AddToPlaylistViewController.reloadPlaylistData))
    }
    
    func loadNoPlaylistsMessage() {
        loadNoDataView(message: Strings.Errors.noPlaylistsAvailable, buttonTitle: nil, buttonPressed: nil)
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

extension AddToPlaylistViewController:UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 58
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 58
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.filteredPlaylistsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let playlist = self.filteredPlaylistsArray[indexPath.row]
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! PlaylistTableViewCell
        
        cell.title?.text = playlist.title
        
        if let lastUpdated = playlist.lastUpdated {
            cell.lastUpdated?.text = lastUpdated.toShortFormatString()
        }
        
        cell.itemCount.text = "Items: " + String(playlist.mediaRefs.count)

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let playlist = self.filteredPlaylistsArray[indexPath.row]
        
        if let item = self.playerHistoryItem {
            
            if let playlistId = playlist.id {
                Playlist.addToPlaylist(playlistId: playlistId, item: item, shouldSaveFullEpisode: shouldSaveFullEpisode) { itemCount in
                    if let cell = self.tableView.cellForRow(at: indexPath) as? PlaylistTableViewCell {
                        
                        if let itemCount = itemCount {
                            cell.itemCount.text = "Items: " + String(describing: itemCount)
                        }
                        
                    }
                }
            }
            
        }
        
        self.tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let index = self.tableView.indexPathForSelectedRow {
            if segue.identifier == "Show Playlist" {
                let playlistDetailTableViewController = segue.destination as! PlaylistDetailTableViewController
                playlistDetailTableViewController.playlistId = self.filteredPlaylistsArray[index.row].id
            }
        }
    }
    
}
