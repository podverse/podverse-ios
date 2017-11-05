//
//  FindSearchTableViewController.swift
//  Podverse
//
//  Created by Mitchell Downey on 7/8/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

import UIKit

class FindSearchTableViewController: PVViewController {
    
    var searchResults = [AudiosearchPodcast]()

    @IBOutlet weak var activityView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    override func viewDidLoad() {
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
        cell.network.text = podcast.network
        cell.categories.text = podcast.categories
        
        cell.pvImage.image = Podcast.retrievePodcastImage(podcastImageURLString: podcast.imageThumbUrl, feedURLString: podcast.rssUrl, managedObjectID: nil, completion: { _ in
            cell.pvImage.sd_setImage(with: URL(string: podcast.imageThumbUrl ?? ""), placeholderImage: #imageLiteral(resourceName: "PodverseIcon"))
        })
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let podcast = self.searchResults[indexPath.row]
        AudiosearchPodcast.showAudiosearchPodcastActions(podcast: podcast, vc: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Show Audiosearch Podcast About" {
            if let audiosearchPodcastVC = segue.destination as? AudiosearchPodcastViewController, let indexPath = self.tableView.indexPathForSelectedRow, indexPath.row < self.searchResults.count {
                let podcast = searchResults[indexPath.row]
                audiosearchPodcastVC.audiosearchId = podcast.id
                audiosearchPodcastVC.feedUrl = podcast.rssUrl
                audiosearchPodcastVC.filterTypeOverride = .about
            }
        }
        
        if segue.identifier == "Show Audiosearch Podcast Clips" {
            if let audiosearchPodcastVC = segue.destination as? AudiosearchPodcastViewController, let indexPath = self.tableView.indexPathForSelectedRow, indexPath.row < self.searchResults.count {
                let podcast = searchResults[indexPath.row]
                audiosearchPodcastVC.audiosearchId = podcast.id
                audiosearchPodcastVC.feedUrl = podcast.rssUrl
                audiosearchPodcastVC.filterTypeOverride = .clips
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
            
            AudioSearchClientSwift.search(query: text, params: nil, type: "shows") { (serviceResponse) in
                
                if let response = serviceResponse.0 {
                    if let results = response["results"] as? [AnyObject] {
                        for result in results {
                            if let searchResult = AudiosearchPodcast.convertJSONToAudiosearchPodcast(result) {
                                self.searchResults.append(searchResult)
                            }
                        }
                    }
                }
                
                if let error = serviceResponse.1 {
                    print(error.localizedDescription)
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
