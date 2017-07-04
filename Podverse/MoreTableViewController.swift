//
//  MoreTableViewController.swift
//  Podverse
//
//  Created by Creon on 12/15/16.
//  Copyright © 2016 Podverse LLC. All rights reserved.
//

import UIKit

class MoreTableViewController: PVViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

}

extension MoreTableViewController:UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        switch indexPath.row {
        case 0:
            cell.textLabel?.text = "Downloads"
        case 1:
            cell.textLabel?.text = "Login"
        case 2:
            cell.textLabel?.text = "About"
        case 3:
            cell.textLabel?.text = "Settings"
        default: break
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch indexPath.row {
        case 0:
            performSegue(withIdentifier: "Show Downloads", sender: nil)
        case 1:
            performSegue(withIdentifier: "Show Login", sender: nil)
        case 2:
            performSegue(withIdentifier: "Show About", sender: nil)
        case 3:
            performSegue(withIdentifier: "Show Settings", sender: nil)
        default: break
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}
