//
//  FindTableViewController.swift
//  Podverse
//
//  Created by Creon on 12/15/16.
//  Copyright © 2016 Podverse LLC. All rights reserved.
//

import UIKit

class FindTableViewController: PVViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    let reachability = PVReachability.shared
    
    let findSearchArray = ["Search", "Add Podcast by RSS", "Browse by Category", "Browse by Network"]
    
    var podcastVC:PodcastsTableViewController? {
        get {
            if let navController = self.tabBarController?.viewControllers?.first as? UINavigationController, let podcastTable = navController.topViewController as? PodcastsTableViewController {
                return podcastTable
            }
            
            return nil
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
}

extension FindTableViewController:UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Podcasts"
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return findSearchArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as UITableViewCell
        let title = findSearchArray[indexPath.row]
        cell.textLabel!.text = title
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            if indexPath.row == 0 {
                self.performSegue(withIdentifier: "Search for Podcasts", sender: tableView)
            }
            else if indexPath.row == 1 {
                if !checkForConnectivity() {
                    showInternetNeededAlertWithDescription(message: "Connect to WiFi or cellular data to add podcast by RSS URL.")
                    return
                }
                let addByRSSAlert = UIAlertController(title: "Add Podcast by RSS Feed", message: "Type the RSS feed URL below.", preferredStyle: UIAlertControllerStyle.alert)
                
                addByRSSAlert.addTextField(configurationHandler: {(textField: UITextField!) in
                    textField.placeholder = "https://rssfeed.example.com/"
                })
                
                addByRSSAlert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
                
                addByRSSAlert.addAction(UIAlertAction(title: "Add", style: .default, handler: { (action: UIAlertAction!) in
                    if let textField = addByRSSAlert.textFields?[0], let text = textField.text {
                        PVSubscriber.subscribeToPodcast(feedUrlString: text)
                    }
                }))
                
                present(addByRSSAlert, animated: true, completion: nil)

            }
            else if indexPath.row == 2 {
                self.performSegue(withIdentifier: "Show Browse Groups", sender: "Categories")
            }
            else {
                self.performSegue(withIdentifier: "Show Browse Groups", sender: "Networks")
            }
        
        tableView.deselectRow(at: indexPath, animated: true)

    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Show Browse Groups", let sender = sender as? String {
            let findBrowseGroupsVC = segue.destination as! FindBrowseGroupsViewController
            
            if sender == "Categories" {
                findBrowseGroupsVC.shouldLoadCategories = true
            } else if sender == "Networks" {
                findBrowseGroupsVC.shouldLoadNetworks = true
            }
        }
    }
    
}
