//
//  MoreTableViewController.swift
//  Podverse
//
//  Created by Creon on 12/15/16.
//  Copyright © 2016 Podverse LLC. All rights reserved.
//

import UIKit

class MoreTableViewController: PVViewController {
    
    let pvAuth = PVAuth.shared
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "More"
        
        addObservers()
    }
    
    deinit {
        removeObservers()
    }
    
    fileprivate func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.loggedInSuccessfully(_:)), name: .loggedInSuccessfully, object: nil)
    }
    
    fileprivate func removeObservers() {
        NotificationCenter.default.removeObserver(self, name: .loggedInSuccessfully, object: nil)
    }
    
}

extension MoreTableViewController:UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        switch indexPath.row {
        case 0:
            cell.textLabel?.text = "Playlists"
        case 1:
            cell.textLabel?.text = "About"
        case 2:
            if let _ = UserDefaults.standard.string(forKey: "idToken") {
                cell.textLabel?.text = "Log out"
            } else {
                cell.textLabel?.text = "Log in"
            }
//        case 3:
//            cell.textLabel?.text = "Settings"
        default: break
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch indexPath.row {
        case 0:
            performSegue(withIdentifier: "Show Playlists", sender: nil)
        case 1:
            if let url = URL(string: BASE_URL + "about") {
                UIApplication.shared.openURL(url)
            }
        case 2:
            if let _ = UserDefaults.standard.string(forKey: "idToken") {
                
                let logoutAlert = UIAlertController(title: "Log out", message: "Are you sure?", preferredStyle: .alert)
                
                logoutAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction!) in
                    self.pvAuth.removeUserInfo()
                    tableView.reloadData()
                }))
                
                logoutAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                
                present(logoutAlert, animated: true, completion: nil)
                
            } else {
                pvAuth.showAuth0Lock(vc: self)
            }
//        case 3:
//            performSegue(withIdentifier: "Show Settings", sender: nil)
        default: break
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}

extension MoreTableViewController {
    func loggedInSuccessfully(_ notification:Notification) {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
}
