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
    
    let findSearchArray = ["Search", "Add Podcast by RSS"]
    
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
        
        self.navigationItem.title = "Find"
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

extension FindTableViewController:UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
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
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                self.performSegue(withIdentifier: "Search for Podcasts", sender: tableView)
            }
            else {
                if reachability.hasInternetConnection() == false {
                    showInternetNeededAlertWithDesciription(message: "Connect to WiFi or cellular data to add podcast by RSS URL.")
                    return
                }
                let addByRSSAlert = UIAlertController(title: "Add Podcast by RSS Feed", message: "Type the RSS feed URL below.", preferredStyle: UIAlertControllerStyle.alert)

                addByRSSAlert.addTextField(configurationHandler: {(textField: UITextField!) in
                    textField.placeholder = "https://rssfeed.example.com/"
                })

                addByRSSAlert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))

                addByRSSAlert.addAction(UIAlertAction(title: "Add", style: .default, handler: { (action: UIAlertAction!) in
                    if let textField = addByRSSAlert.textFields?[0], let text = textField.text {
                        PVSubscriber.subscribeToPodcast(feedUrlString: text, podcastTableDelegate: self.podcastVC)
                    }
                }))
                
                present(addByRSSAlert, animated: true, completion: nil)
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)

    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == TO_PLAYER_SEGUE_ID {
//            TODO
//            let mediaPlayerViewController = segue.destinationViewController as! MediaPlayerViewController
//            mediaPlayerViewController.hidesBottomBarWhenPushed = true
        }
    }
    
}
