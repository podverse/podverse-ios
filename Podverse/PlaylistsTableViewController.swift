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
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.activityIndicator.hidesWhenStopped = true
        
        PVAuth.shared.delegate = self
        
        loadPlaylistData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkAuthorizationAndConnectivity()
    }
    
    func checkAuthorizationAndConnectivity() {
        var message = ErrorMessages.noPlaylistsAvailable.text
        var buttonTitle = "Retry"
        var selector:Selector = #selector(PlaylistsTableViewController.loadPlaylistData)
        let isLoggedIn = PVAuth.userIsLoggedIn
        
        if self.reachability.hasInternetConnection() == false {
            message = ErrorMessages.noPlaylistsInternet.text
        }
        else if !isLoggedIn {
            message = ErrorMessages.noPlaylistsNotLoggedIn.text
            buttonTitle = "Login"

            selector = #selector(PlaylistsTableViewController.presentLogin)
        }
        
        if let noDataView = self.view.subviews.first(where: { $0.tag == kNoDataViewTag}) {
            if let actionButtonView = noDataView.subviews.first(where: {$0 is UIButton}), let actionButton = actionButtonView as? UIButton {
                actionButton.setTitle(buttonTitle, for: .normal)
                actionButton.addTarget(self, action: selector, for: .touchUpInside)
            }
            
            if let messageView = noDataView.subviews.first(where: {$0 is UILabel}), let messageLabel = messageView as? UILabel {
                messageLabel.text = message
            }
        }
        else {
            self.addNoDataViewWithMessage(message, buttonTitle: buttonTitle, buttonImage: nil, retryPressed: selector)
        }
    }
    
    func presentLogin() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginVC") as? LoginViewController {
            self.present(loginVC, animated: true, completion: nil)
        }
    }
    
    func loadPlaylistData() {
        Playlist.retrievePlaylistsFromServer() { (playlists) -> Void in
            self.showIndicator()
            self.reloadPlaylistData(playlists: playlists)
        }
    }
    
    func reloadPlaylistData(playlists: [Playlist]? = nil) {
        self.tableView.isHidden = true

        if let pArray = playlists, pArray.count > 0 {
            self.playlistsArray = pArray
            self.tableView.isHidden = false
        }
        
        self.activityIndicator.stopAnimating()
        self.tableView.reloadData()
    }
    
    func showIndicator() {
        self.activityIndicator.startAnimating()
        self.activityIndicator.isHidden = false
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
        
        if let itemCount = playlist.itemCount {
            cell.itemCount.text = "Items: " + itemCount
        } else {
            cell.itemCount.text = "Items: 0"
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

extension PlaylistsTableViewController:PVAuthDelegate {
    func loggedInSuccessfully() {
        self.loadPlaylistData()
    }
}
