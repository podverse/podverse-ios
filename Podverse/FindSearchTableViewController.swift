//
//  FindSearchTableViewController.swift
//  Podverse
//
//  Created by Mitchell Downey on 7/8/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

import UIKit

class FindSearchTableViewController: PVViewController {
    
    var searchResults = [SearchPodcast]()

    @IBOutlet weak var activityView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Search"
        
        self.searchBar.delegate = self
        
        self.activityIndicator.hidesWhenStopped = true
        hideActivityIndicator()
        
        self.tableView.isHidden = true
        
        loadSearchForPodcastsMessage()
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
        
        showNoDataView()
        
    }
    
    func loadNoInternetMessage() {
        loadNoDataView(message: Strings.Errors.noClipsInternet, buttonTitle: "Retry", buttonPressed: #selector(ClipsTableViewController.resetAndRetrieveClips))
    }
    
    func loadNoResultsMessage() {
        loadNoDataView(message: Strings.Errors.noSearchResultsFound, buttonTitle: nil, buttonPressed: nil)
    }
    
    func loadSearchForPodcastsMessage() {
        loadNoDataView(message: "Search for podcasts by title", buttonTitle: nil, buttonPressed: nil)
    }
    
    func showActivityIndicator() {
        self.tableView.isHidden = true
        self.activityIndicator.startAnimating()
        self.activityView.isHidden = false
    }
    
    func hideActivityIndicator() {
        self.activityIndicator.stopAnimating()
        self.activityView.isHidden = true
    }
    
}

extension FindSearchTableViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 96.5
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! PodcastSearchResultTableViewCell
        
        let podcast = self.searchResults[indexPath.row]
        
        cell.title.text = podcast.title
        cell.hosts.text = podcast.hosts
        cell.categories.text = podcast.categories
        
        cell.pvImage.sd_setImage(with: URL(string: podcast.imageUrl ?? ""), placeholderImage: #imageLiteral(resourceName: "PodverseIcon"))
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let podcast = self.searchResults[indexPath.row]
        SearchPodcast.showSearchPodcastActions(podcast: podcast, vc: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Show Search Podcast About" {
            if let searchPodcastVC = segue.destination as? SearchPodcastViewController, let indexPath = self.tableView.indexPathForSelectedRow, indexPath.row < self.searchResults.count {
                let podcast = searchResults[indexPath.row]
                searchPodcastVC.id = podcast.id
                searchPodcastVC.feedUrl = podcast.rssUrl
                searchPodcastVC.filterTypeOverride = .about
            }
        }
        
        if segue.identifier == "Show Search Podcast Clips" {
            if let searchPodcastVC = segue.destination as? SearchPodcastViewController, let indexPath = self.tableView.indexPathForSelectedRow, indexPath.row < self.searchResults.count {
                let podcast = searchResults[indexPath.row]
                searchPodcastVC.id = podcast.id
                searchPodcastVC.feedUrl = podcast.rssUrl
                searchPodcastVC.filterTypeOverride = .clips
            }
        }
    }
    
}

extension FindSearchTableViewController: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        
        self.searchResults.removeAll()
        
        if let text = searchBar.text {
            
            guard checkForConnectivity() else {
                loadNoInternetMessage()
                return
            }
            
            showActivityIndicator()
            
            SearchPodcast.searchPodcastsByTitle(title: text) { searchPodcasts in
                if let searchPodcasts = searchPodcasts {
                    self.searchResults = searchPodcasts
                }
                
                DispatchQueue.main.async {
                    self.hideActivityIndicator()

                    if self.searchResults.isEmpty {
                        self.loadNoResultsMessage()
                    } else {
                        self.tableView.reloadData()
                        self.tableView.isHidden = false
                    }

                }
            }
            
        }
        
    }
}
