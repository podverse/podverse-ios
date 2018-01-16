//
//  FindBrowseGroupsViewController.swift
//  Podverse
//
//  Created by Mitchell Downey on 10/22/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

//import UIKit
//
//class FindBrowseGroupsViewController: PVViewController {
//    
//    var categories = [SearchCategory]()
//    var networks = [SearchNetwork]()
//    
//    var categoryParentId:Int64?
//    var shouldLoadCategories:Bool = false
//    var shouldLoadNetworks:Bool = false
//    
//    @IBOutlet weak var tableView: UITableView!
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        if self.shouldLoadCategories {
//            
//            self.title = "Categories"au
//            
//            SearchCategory.retrieveCategoriesFromServer(parentId: nil, { categoriesArray in
//                DispatchQueue.main.async {
//                    if let categoriesArray = categoriesArray {
//                        let filteredArray = SearchCategory.filterCategories(categories: categoriesArray, parentId: self.categoryParentId)
//                        self.categories = filteredArray
//                        self.tableView.reloadData()
//                    }
//                }
//            })
//        } else if self.shouldLoadNetworks {
//            
//            self.title = "Networks"
//            
//            SearchNetwork.retrieveNetworksFromServer({ networksArray in
//                DispatchQueue.main.async {
//                    if let networksArray = networksArray {
//                        self.networks = networksArray
//                        self.tableView.reloadData()
//                    }
//                }
//            })
//        }
//
//    }
//    
//}
//
//extension FindBrowseGroupsViewController:UITableViewDelegate, UITableViewDataSource {
//
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        if self.shouldLoadCategories {
//            return self.categories.count
//        } else {
//            return self.networks.count
//        }
//    }
//    
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = self.tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as UITableViewCell
//        
//        if self.shouldLoadCategories {
//            let title = self.categories[indexPath.row].name
//            cell.textLabel?.text = title
//        } else {
//            let title = self.networks[indexPath.row].name
//            cell.textLabel?.text = title
//        }
//        
//        return cell
//    }
//    
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let sender = self.shouldLoadCategories ? "Categories" : "Networks"
//        self.performSegue(withIdentifier: "Show Browse Podcasts", sender: sender)
//    }
//    
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if segue.identifier == "Show Browse Podcasts", let findBrowsePodcastsVC = segue.destination as? FindBrowsePodcastsViewController, let indexPath = self.tableView.indexPathForSelectedRow {
//            
//            if let sender = sender as? String, sender == "Categories" {
//                if indexPath.row < self.categories.count {
//                    let category = self.categories[indexPath.row]
//                    findBrowsePodcastsVC.groupTitle = category.name
//                    findBrowsePodcastsVC.categoryName = category.name
//                }
//            } else {
//                if indexPath.row < self.networks.count {
//                    let network = self.networks[indexPath.row]
//                    if let name = network.name {
//                        findBrowsePodcastsVC.groupTitle = name
//                        findBrowsePodcastsVC.networkName = name
//                    }
//                }
//            }
//            
//        }
//    }
//    
//}

