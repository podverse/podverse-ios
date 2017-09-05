//
//  FindSearchTableViewController.swift
//  Podverse
//
//  Created by Mitchell Downey on 7/8/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

import UIKit

class FindSearchTableViewController: PVViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var searchResults = [PodcastSearchResult]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        AudioSearchClientSwift.getAudiosearchAccessToken()
        
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension FindSearchTableViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 92
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! PodcastSearchResultTableViewCell
        
        let podcast = searchResults[indexPath.row]
        
        cell.title.text = podcast.title
        cell.network.text = podcast.network
        cell.categories.text = podcast.categories

        Podcast.retrievePodcastImage(podcastImageURLString: podcast.imageUrl) { (podcastImage) -> Void in
            if let visibleRows = self.tableView.indexPathsForVisibleRows, visibleRows.contains(indexPath), 
               let existingCell = self.tableView.cellForRow(at: indexPath) as? PodcastSearchResultTableViewCell {
                existingCell.pvImage.image = podcastImage
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let podcast = searchResults[indexPath.row]
        if let feedUrl = podcast.rssUrl {
            var isSubscribed = false
            
            if let _ = Podcast.podcastForFeedUrl(feedUrlString: feedUrl) {
                isSubscribed = true
            }
            
            let podcastActions = UIAlertController(title: "", message: "", preferredStyle: .actionSheet)
            
            if isSubscribed == true {
                podcastActions.addAction(UIAlertAction(title: "Unsubscribe", style: .default, handler: { action in
                    PVDeleter.deletePodcast(podcastId: nil, feedUrl: feedUrl)
                }))
            } else {
                podcastActions.addAction(UIAlertAction(title: "Subscribe", style: .default, handler: { action in
                    PVSubscriber.subscribeToPodcast(feedUrlString: feedUrl)
                }))
            }
            
            podcastActions.addAction(UIAlertAction(title: "About", style: .default, handler: { action in
                // TODO segue to about page
            }))
            
            podcastActions.addAction(UIAlertAction(title: "Episodes", style: .default, handler: { action in
                // TODO segue to podcast clip's page
            }))
            
            podcastActions.addAction(UIAlertAction(title: "Clips", style: .default, handler: { action in
                // TODO segue to podcast clip's page
            }))
            
            podcastActions.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            self.present(podcastActions, animated: true, completion: nil)
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
                            if let searchResult = PodcastSearchResult.convertJSONToSearchResult(json: result) {
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
