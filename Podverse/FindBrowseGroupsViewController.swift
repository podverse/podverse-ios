//
//  FindBrowseGroupsViewController.swift
//  Podverse
//
//  Created by Mitchell Downey on 10/22/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

import UIKit

class FindBrowseGroupsViewController: PVViewController {
    
    var categories = [AudiosearchCategory]()
    var networks = [AudiosearchNetwork]()
    
    var categoryParentId:Int64?
    var shouldLoadCategories:Bool = false
    var shouldLoadNetworks:Bool = false
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if self.shouldLoadCategories {
            
            self.title = "Categories"
            
            AudiosearchCategory.retrieveCategoriesFromServer(parentId: nil, { categoriesArray in
                DispatchQueue.main.async {
                    if let categoriesArray = categoriesArray {
                        let filteredArray = AudiosearchCategory.filterCategories(categories: categoriesArray, parentId: self.categoryParentId)
                        self.categories = filteredArray
                        self.tableView.reloadData()
                    }
                }
            })
        } else if self.shouldLoadNetworks {
            
            self.title = "Networks"
            
            AudiosearchNetwork.retrieveNetworksFromServer({ networksArray in
                DispatchQueue.main.async {
                    if let networksArray = networksArray {
                        self.networks = networksArray
                        self.tableView.reloadData()
                    }
                }
            })
        }

    }
    
}

extension FindBrowseGroupsViewController:UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.shouldLoadCategories {
            return self.categories.count
        } else {
            return self.networks.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as UITableViewCell
        
        if self.shouldLoadCategories {
            let title = self.categories[indexPath.row].name
            cell.textLabel!.text = title
        } else {
            let title = self.networks[indexPath.row].name
            cell.textLabel!.text = title
        }
        
        return cell
    }
    
}
