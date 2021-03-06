//
//  FindSearchTableViewController.swift
//  Podverse
//
//  Created by Mitchell Downey on 7/8/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

import UIKit

class FindSearchTableViewController: PVViewController {
    
    var podcasts = [SearchPodcast]()

    @IBOutlet weak var activityView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Search"
        
        self.searchBar.delegate = self
        self.searchBar.returnKeyType = .done
        
        self.activityIndicator.hidesWhenStopped = true
        hideActivityIndicator()
        
        self.tableView.isHidden = true
        
        let requestPodcast = UIBarButtonItem(title: "Request", style: .plain, target: self, action: #selector(segueToRequestPodcastForm))
        self.navigationItem.rightBarButtonItems = [requestPodcast]
        
        loadSearchForPodcastsMessage()
    }
    
    @objc func segueToRequestPodcastForm() {
        self.tableView.reloadData()
        if let webKitVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "WebKitVC") as? WebKitViewController {
            webKitVC.urlString = kFormRequestPodcastUrl
            self.hideNowPlayingBar()
            self.navigationController?.pushViewController(webKitVC, animated: true)
        }
    }
    
    func loadNoDataView(message: String, buttonTitle: String?, buttonPressed: Selector?) {
        
        if let noDataView = self.view.subviews.first(where: { $0.tag == kNoDataViewTag}) {
            noDataView.removeFromSuperview()
        }

        self.addNoDataViewWithMessage(message, buttonTitle: buttonTitle, buttonImage: nil, retryPressed: buttonPressed)

        showNoDataView()
        
    }
    
    func loadNoInternetMessage() {
        loadNoDataView(message: Strings.Errors.noClipsInternet, buttonTitle: "Retry", buttonPressed: #selector(ClipsTableViewController.resetAndRetrieveClips))
    }
    
    func loadNoResultsMessage() {
        loadNoDataView(message: Strings.Errors.noSearchResultsFound, buttonTitle: "Request a podcast", buttonPressed: #selector(segueToRequestPodcastForm))
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
    
    @objc fileprivate func searchPodcasts(_ text:String) {
        self.podcasts.removeAll()
        
        guard checkForConnectivity() else {
            loadNoInternetMessage()
            return
        }
        
        showActivityIndicator()
        
        SearchPodcast.searchPodcastsByTitle(title: text) { searchPodcasts in
            if let searchPodcasts = searchPodcasts {
                self.podcasts = searchPodcasts
            }
            
            DispatchQueue.main.async {
                self.hideActivityIndicator()
                
                if self.podcasts.isEmpty {
                    self.loadNoResultsMessage()
                } else {
                    self.tableView.reloadData()
                    self.tableView.isHidden = false
                }
                
            }
        }
    }
    
}

extension FindSearchTableViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 96.5
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.podcasts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! PodcastSearchResultTableViewCell
        
        let podcast = self.podcasts[indexPath.row]
        
        cell.title.text = podcast.title
        cell.hosts.text = podcast.hosts
        cell.categories.text = podcast.categories
        
        cell.pvImage.sd_setImage(with: URL(string: podcast.imageUrl ?? ""), placeholderImage: #imageLiteral(resourceName: "PodverseIcon"))
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let podcast = self.podcasts[indexPath.row]
        SearchPodcast.showSearchPodcastActions(searchPodcast: podcast, vc: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Show Search Podcast" {
            if let searchPodcastVC = segue.destination as? SearchPodcastViewController, let indexPath = self.tableView.indexPathForSelectedRow, indexPath.row < self.podcasts.count {
                let podcast = podcasts[indexPath.row]
                searchPodcastVC.searchPodcast = podcast
                
                if let sender = sender as? String, sender == "About" {
                    searchPodcastVC.filterTypeOverride = .about
                } else if let sender = sender as? String, sender == "Clips" {
                    searchPodcastVC.filterTypeOverride = .clips
                } else if let sender = sender as? String, sender == "Episodes" {
                    searchPodcastVC.filterTypeOverride = .episodes
                }
            }
        }
    }
    
}

extension FindSearchTableViewController: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if let text = searchBar.text, text.count > 2 {
            NSObject.cancelPreviousPerformRequests(withTarget: self) 
            perform(#selector(searchPodcasts(_:)), with: text, afterDelay: 0.4)
        }
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
