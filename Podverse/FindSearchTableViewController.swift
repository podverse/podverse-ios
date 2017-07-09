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
    
    var searchActive:Bool = false
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

        DispatchQueue.global().async {
            Podcast.retrievePodcastUIImage(podcastFeedUrl: nil, podcastImageUrl: podcast.imageUrl) { (podcastImage) -> Void in
                DispatchQueue.main.async {
                    if let visibleRows = self.tableView.indexPathsForVisibleRows, visibleRows.contains(indexPath) {
                        let existingCell = self.tableView.cellForRow(at: indexPath) as! PodcastSearchResultTableViewCell
                        existingCell.pvImage.image = podcastImage
                    }
                }
            }
        }
        
        return cell
    }
    
}

extension FindSearchTableViewController: UISearchBarDelegate {
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchActive = true
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchActive = false
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false
        
        if let text = searchBar.text {
            AudioSearchClientSwift.search(query: text, params: nil, type: "shows") { (serviceResponse) in
                
                self.searchResults = [PodcastSearchResult]()
                
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
                    print(error)
                }
                
            }
        }
        
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    }
    
}
