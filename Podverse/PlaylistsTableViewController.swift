//
//  PlaylistsTableViewController.swift
//  Podverse
//
//  Created by Creon on 12/15/16.
//  Copyright © 2016 Podverse LLC. All rights reserved.
//

import UIKit

class PlaylistsTableViewController: PVViewController {
    
    var playlistsArray = [Playlist]()
    let reachability = PVReachability.shared

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var retryButton: UIButton!
    @IBOutlet weak var statusMessage: UILabel!
    @IBOutlet weak var tableView: UITableView!

    @IBAction func retryButtonTouched(_ sender: Any) {
        showIndicator()
        Playlist.retrievePlaylistsFromServer() { (playlists) -> Void in
            self.reloadPlaylistData(playlists: playlists)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.activityIndicator.hidesWhenStopped = true
        showIndicator()
        
        Playlist.retrievePlaylistsFromServer() { (playlists) -> Void in
            self.reloadPlaylistData(playlists: playlists)
        }
        
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

extension PlaylistsTableViewController:UITableViewDelegate, UITableViewDataSource {
    
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
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "playlistCell", for: indexPath) as! PlaylistTableViewCell
        
        cell.title?.text = playlist.title
        
        if let lastUpdated = playlist.lastUpdated {
            cell.lastUpdated?.text = lastUpdated.toShortFormatString()
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "Show Playlist", sender: nil)
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
