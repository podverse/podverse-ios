//
//  PlaylistsTableViewController.swift
//  Podverse
//
//  Created by Creon on 12/15/16.
//  Copyright © 2016 Podverse LLC. All rights reserved.
//

import UIKit

class PlaylistsTableViewController: PVViewController {
    
    var allPlaylistsArray = [Playlist]()
    var filteredPlaylistsArray = [Playlist]()
    let reachability = PVReachability.shared
    
    var filterTypeSelected: PlaylistFilter = .myPlaylists {
        didSet {
            self.tableViewHeader.filterTitle = self.filterTypeSelected.text
            UserDefaults.standard.set(filterTypeSelected.text, forKey: kPlaylistsTableFilterType)
            
            guard checkForAuthorization() else {
                return
            }
            
            if self.allPlaylistsArray.count > 0 {
                self.reloadPlaylistData()
            }
        }
    }

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var activityIndicatorView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewHeader: FiltersTableHeaderView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Playlists"
        
        addObservers()
        
        self.activityIndicator.hidesWhenStopped = true
        self.activityIndicatorView.isHidden = true

        self.tableView.isHidden = true
        
        self.tableViewHeader.delegate = self
        self.tableViewHeader.setupViews()
        
        if let savedFilterType = UserDefaults.standard.value(forKey: kPlaylistsTableFilterType) as? String, let clipFilterType = PlaylistFilter(rawValue: savedFilterType) {
            self.filterTypeSelected = clipFilterType
        } else {
            self.filterTypeSelected = .myPlaylists
        }
        
        retrievePlaylists()
    }
    
    deinit {
        removeObservers()
    }
    
    fileprivate func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.loggedInSuccessfully(_:)), name: .loggedInSuccessfully, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.decrementPlaylistItemCount(_:)), name: .removedPlaylistItem, object: nil)
    }
    
    fileprivate func removeObservers() {
        NotificationCenter.default.removeObserver(self, name: .loggedInSuccessfully, object: nil)
        NotificationCenter.default.removeObserver(self, name: .removedPlaylistItem, object: nil)
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
            if filterTypeSelected == .myPlaylists && playlist.ownerId == UserDefaults.standard.string(forKey: "userId") {
                self.filteredPlaylistsArray.append(playlist)
            } else if filterTypeSelected == .following && playlist.ownerId != UserDefaults.standard.string(forKey: "userId") {
                self.filteredPlaylistsArray.append(playlist)
            }
        }
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
    
    func checkForResults(playlists: [Playlist]?) -> Bool {
        
        let message = Strings.Errors.noPlaylistsAvailable
        
        guard let playlists = playlists, playlists.count > 0 else {
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
                button.setTitleColor(.blue, for: .normal)
            }

        }
        else {
            self.addNoDataViewWithMessage(message, buttonTitle: buttonTitle, buttonImage: nil, retryPressed: buttonPressed)
        }

        self.tableView.isHidden = true
        showNoDataView()
        
    }
    
    func showActivityIndicator() {
        self.activityIndicator.startAnimating()
        self.activityIndicatorView.isHidden = false
        self.tableView.isHidden = true
        self.hideNoDataView()
    }
    
    func hideActivityIndicator() {
        self.activityIndicator.stopAnimating()
        self.activityIndicatorView.isHidden = true
    }
    
    func reloadPlaylistData() {
        self.filterPlaylists()
        hideActivityIndicator()
        
        if filterTypeSelected == .following, self.filteredPlaylistsArray.count < 1 {
            let message = "Other people's playlists that you follow will be listed here."
            loadNoDataView(message: message, buttonTitle: nil, buttonPressed: nil)
        } else {
            self.tableView.isHidden = false
            self.tableView.reloadData()
        }
        
    }
    
    @objc func presentLogin() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginVC") as? LoginViewController {
            self.present(loginVC, animated: true, completion: nil)
        }
    }
    
    @objc func decrementPlaylistItemCount(_ notification:Notification) {
        if let obj = notification.object as? [String], obj.count > 1 {
            let playlistId = obj[0]
            let mediaRefId = obj[1]
            if let allPlaylist = self.allPlaylistsArray.first(where: {$0.id == playlistId}) {
                allPlaylist.mediaRefs = allPlaylist.mediaRefs.filter { $0.id != mediaRefId}
            }
            
            if let filteredPlaylist = self.filteredPlaylistsArray.first(where: {$0.id == playlistId}), let index = self.filteredPlaylistsArray.index(where: {$0.id == playlistId}) {
                filteredPlaylist.mediaRefs = filteredPlaylist.mediaRefs.filter { $0.id != mediaRefId}
                self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
            }
        }
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
        return self.filteredPlaylistsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let playlist = self.filteredPlaylistsArray[indexPath.row]
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "playlistCell", for: indexPath) as! PlaylistTableViewCell
        
        cell.title?.text = playlist.title
        
        if let lastUpdated = playlist.lastUpdated {
            cell.lastUpdated?.text = lastUpdated.toShortFormatString()
        }
        
        cell.itemCount.text = "Items: " + String(playlist.mediaRefs.count)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "Show Playlist", sender: nil)
        self.tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {

        let row = indexPath.row
        
        if self.filteredPlaylistsArray.count > row {
            let playlist = self.filteredPlaylistsArray[row]
            
            if let id = playlist.id {
                var actionTitle = "Unfollow"
                
                if let userId = UserDefaults.standard.string(forKey: "userId"), userId == playlist.ownerId {
                    actionTitle = "Delete"
                    
                    let deleteAction = UITableViewRowAction(style: .default, title: actionTitle, handler: {action, indexPath in

                        Playlist.deletePlaylistFromServer(id: id) { wasSuccessful in
                            DispatchQueue.main.async {
                                if (wasSuccessful) {
                                    self.filteredPlaylistsArray.remove(at: row)
                                    self.tableView.deleteRows(at: [indexPath], with: .fade)
                                } else {
                                    let actions = UIAlertController(title: "Failed to delete playlist", message: "Please check your internet connection and try again.",preferredStyle: .alert)
                                    
                                    actions.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                                    
                                    self.present(actions, animated: true, completion: nil)
                                }
                            }
                        }
                    })
                    
                    return [deleteAction]
                } else {
                    let unsubscribeAction = UITableViewRowAction(style: .default, title: actionTitle, handler: {action, indexPath in
                        
                        Playlist.unsubscribeFromPlaylistOnServer(id: id) { wasSuccessful in
                            DispatchQueue.main.async {
                                if (wasSuccessful) {
                                    self.filteredPlaylistsArray.remove(at: row)
                                    self.tableView.deleteRows(at: [indexPath], with: .fade)
                                } else {
                                    let actions = UIAlertController(title: "Failed to unsubscribe from playlist", message: "Please check your internet connection and try again.", preferredStyle: .alert)
                                    
                                    actions.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                                    
                                    self.present(actions, animated: true, completion: nil)
                                }
                            }
                        }
                    })
                    
                    return [unsubscribeAction]
                }
            }
        }
            
        return []
    }
        
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let index = self.tableView.indexPathForSelectedRow {
            if segue.identifier == "Show Playlist" {
                let playlistDetailTableViewController = segue.destination as! PlaylistDetailTableViewController
                playlistDetailTableViewController.playlistId = self.filteredPlaylistsArray[index.row].id
                playlistDetailTableViewController.ownerId = self.filteredPlaylistsArray[index.row].ownerId
            }
        }
    }
    
}

extension PlaylistsTableViewController {
    
    @objc func loggedInSuccessfully(_ notification:Notification) {
        retrievePlaylists()
    }
    
    @objc func removedPlaylistItem(_ notification:Notification) {
        
    }
    
}

extension PlaylistsTableViewController:FilterSelectionProtocol {
    
    func filterButtonTapped() {
        let alert = UIAlertController(title: "Show Only", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: PlaylistFilter.myPlaylists.text, style: .default, handler: { action in
            self.filterTypeSelected = .myPlaylists
        }))
        
        alert.addAction(UIAlertAction(title: PlaylistFilter.following.text, style: .default, handler: { action in
            self.filterTypeSelected = .following
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func sortingButtonTapped() {
        
    }
    
    func sortByRecent() {
        
    }
    
    func sortByTop() {
        
    }
    
    func sortByTopWithTimeRange(timeRange: SortingTimeRange) {
        
    }
    
}
