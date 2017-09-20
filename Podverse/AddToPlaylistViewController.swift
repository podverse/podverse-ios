//
//  AddToPlaylistViewController.swift
//  Podverse
//
//  Created by Mitchell Downey on 8/26/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

import UIKit

class AddToPlaylistViewController: UIViewController {

    var playerHistoryItem: PlayerHistoryItem?
    var playlistsArray = [Playlist]()
    let reachability = PVReachability.shared
    var shouldSaveFullEpisode = false
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var clipTitle: UILabel!
    @IBOutlet weak var episodePubDate: UILabel!
    @IBOutlet weak var episodeTitle: UILabel!
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var podcastImage: UIImageView!
    @IBOutlet weak var podcastTitle: UILabel!
    @IBOutlet weak var retryButton: UIButton!
    @IBOutlet weak var statusMessage: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var time: UILabel!
    
    @IBAction func retryButtonTouched(_ sender: Any) {
        showIndicator()
        Playlist.retrievePlaylistsFromServer() { (playlists) -> Void in
            self.reloadPlaylistData(playlists: playlists)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let item = playerHistoryItem {
            
            self.podcastTitle.text = item.podcastTitle
            
            self.episodeTitle.text = item.episodeTitle
            
            if shouldSaveFullEpisode {
                self.clipTitle.text = "Full Episode"
                self.time.text = "--:--"
            } else {
                self.clipTitle.text = item.clipTitle
                
                if let time = item.readableStartAndEndTime() {
                    self.time.text = time
                }
            }
                        
            if let episodePubDate = item.episodePubDate {
                self.episodePubDate.text = episodePubDate.toShortFormatString()
            }
            
            self.podcastImage.sd_setImage(with: URL(string: item.podcastImageUrl ?? ""), placeholderImage: #imageLiteral(resourceName: "PodverseIcon"))
        }
        
        self.activityIndicator.hidesWhenStopped = true
        showIndicator()
        
        let new = UIBarButtonItem(title: "New", style: .plain, target: self, action: #selector(showCreatePlaylist))
        self.navigationItem.rightBarButtonItem = new
        
        Playlist.retrievePlaylistsFromServer() { (playlists) -> Void in
            self.reloadPlaylistData(playlists: playlists)
        }
        
    }
    
    func showCreatePlaylist() {
        
        if self.reachability.hasInternetConnection() == false {
            self.showStatusMessage(message: "You must connect to the internet to create a playlist.")
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
                        self.playlistsArray.append(playlist)
                        self.tableView.reloadData()
                    }
                }
            }
        }))
        
        self.present(createPlaylist, animated: true, completion: nil)
        
    }
    
    func reloadPlaylistData(playlists: [Playlist]? = nil) {
        
        if self.reachability.hasInternetConnection() == false {
            self.showStatusMessage(message: "You must connect to the internet to load playlists.")
            return
        }
        
        guard let pArray = playlists, pArray.count > 0 else {
            self.showStatusMessage(message: "No playlists available")
            return
        }
        
        for playlist in pArray {
            self.playlistsArray.append(playlist)
        }
        
        self.showPlaylistsView()
        self.tableView.reloadData()
        
    }
    
    func showStatusMessage(message: String) {
        self.activityIndicator.stopAnimating()
        self.statusMessage.text = message
        self.tableView.isHidden = true
        self.loadingView.isHidden = false
        self.statusMessage.isHidden = false
        
        if message == "You must connect to the internet to load playlists." {
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
    
    func showPlaylistsView() {
        self.activityIndicator.stopAnimating()
        self.tableView.isHidden = false
        self.loadingView.isHidden = true
        self.statusMessage.isHidden = true
        self.retryButton.isHidden = true
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
        return self.playlistsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let playlist = self.playlistsArray[indexPath.row]
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! PlaylistTableViewCell
        
        cell.title?.text = playlist.title
        
        if let lastUpdated = playlist.lastUpdated {
            cell.lastUpdated?.text = lastUpdated.toShortFormatString()
        }
        
        if let itemCount = playlist.itemCount {
            cell.itemCount.text = "Items: " + itemCount
        }

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let playlist = self.playlistsArray[indexPath.row]
        
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
                playlistDetailTableViewController.playlistId = self.playlistsArray[index.row].id
            }
        }
    }
    
}
