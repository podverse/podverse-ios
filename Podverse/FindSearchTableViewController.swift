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

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    override func viewDidLoad() {
        self.searchBar.delegate = self
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
        
        if let text = searchBar.text {
            AudioSearchClientSwift.search(query: text, params: nil, type: "shows") { (serviceResponse) in
                
                self.searchResults.removeAll()
                
                if let response = serviceResponse.0 {
                    //                let page = response["page"] as? String
                    //                let query = response["query"] as? String
                    //                let results_per_page = response["results_per_page"] as? String
                    //                let total_results = response["total_results"] as? String
                    
                    if let results = response["results"] as? [AnyObject] {
                        for result in results {
                            if let searchResult = AudiosearchPodcast.convertJSONToAudiosearchPodcast(result) {
                                self.searchResults.append(searchResult)
                            }
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }
                
                if let error = serviceResponse.1 {
                    print(error.localizedDescription)
                }
                
            }
        }
        
    }
}
