//
//  FindBrowsePodcastsViewController.swift
//  Podverse
//
//  Created by Mitchell Downey on 10/22/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

import UIKit

class FindBrowsePodcastsViewController: PVViewController {
    
    var podcasts = [SearchPodcast]()
    var groupTitle = ""
    var categoryName:String?
    var networkName:String?
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var params = Dictionary<String,String>()
        
        if let categoryName = categoryName {
            self.title = "Category"
            params["filters[categories.name]"] = categoryName
        } else if let networkName = networkName {
            self.title = "Network"
            params["filters[network.name]"] = networkName
        }
        
        params["sort_by"] = "buzz_score"
        params["sort_order"] = "desc"
        
//        SearchClientSwift.search(query: "*", params: params, type: "shows") { (serviceResponse) in
//            
//            self.podcasts.removeAll()
//            
//            if let response = serviceResponse.0 {
//                //                let page = response["page"] as? String
//                //                let query = response["query"] as? String
//                //                let results_per_page = response["results_per_page"] as? String
//                //                let total_results = response["total_results"] as? String
//                
//                if let results = response["results"] as? [AnyObject] {
//                    for result in results {
//                        if let searchResult = SearchPodcast.convertJSONToSearchPodcast(result) {
//                            self.podcasts.append(searchResult)
//                        }
//                    }
//                }
//                
//                DispatchQueue.main.async {
//                    self.tableView.reloadData()
//                }
//            }
//            
//            if let error = serviceResponse.1 {
//                print(error.localizedDescription)
//            }
//            
//        }
        
    }
    
}

extension FindBrowsePodcastsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.groupTitle
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 96.5
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 96.5
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.podcasts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! PodcastSearchResultTableViewCell
        
        let podcast = self.podcasts[indexPath.row]

        cell.title.text = podcast.title
        cell.hosts.text = podcast.hosts
        cell.categories.text = podcast.categories

        cell.pvImage.image = Podcast.retrievePodcastImage(podcastImageURLString: podcast.imageUrl, feedURLString: nil, completion: { image in
            cell.pvImage.image = image
        })
        
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
                searchPodcastVC.filterTypeOverride = .about
            }
        }
        
    }
    
}
