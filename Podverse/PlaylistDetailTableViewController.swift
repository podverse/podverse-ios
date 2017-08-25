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
    @IBOutlet weak var loadingView: UIView!
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

//        guard let mArray = mediaRefs, mArray.count > 0 else {
//            self.showStatusMessage(message: "No playlist items available")
//            return
//        }
//        
//        for mediaRef in mArray {
//            self.mediaRefsArray.append(mediaRef)
//        }
        
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
        return 0
//        return self.playlistsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let playlist = self.playlistsArray[indexPath.row]
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! PlaylistDetailTableViewCell
        
//        cell.title?.text = playlist.title
//        
//        if let lastUpdated = playlist.lastUpdated {
//            cell.lastUpdated?.text = playlist.lastUpdated?.toShortFormatString()
//        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("selected mediaRef")
    }
    
}
