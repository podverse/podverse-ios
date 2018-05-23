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
        NotificationCenter.default.addObserver(self, selector: #selector(self.loggingIn(_:)), name: .loggingIn, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.loggedInSuccessfully(_:)), name: .loggedInSuccessfully, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.loginFailed(_:)), name: .loginFailed, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.loggedOutSuccessfully(_:)), name: .loggedOutSuccessfully, object: nil)
    }
    
    fileprivate func removeObservers() {
        NotificationCenter.default.removeObserver(self, name: .loggingIn, object: nil)
        NotificationCenter.default.removeObserver(self, name: .loggedInSuccessfully, object: nil)
        NotificationCenter.default.removeObserver(self, name: .loginFailed, object: nil)
        NotificationCenter.default.removeObserver(self, name: .loggedOutSuccessfully, object: nil)
    }
    
}

extension MoreTableViewController:UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        switch indexPath.row {
        case 0:
            cell.textLabel?.text = "Playlists"
        case 1:
            if let _ = UserDefaults.standard.string(forKey: "idToken") {
                cell.textLabel?.text = "Log out"
            } else {
                cell.textLabel?.text = "Log in"
            }
        case 2:
            cell.textLabel?.text = "About"
        case 3:
            cell.textLabel?.text = "Contact"
        case 4:
            cell.textLabel?.text = "Settings"
        default: break
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch indexPath.row {
        case 0:
            performSegue(withIdentifier: "Show Playlists", sender: nil)
        case 1:
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
        case 2:
            if let url = URL(string: BASE_URL + "about"), let webVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AboutVC") as? AboutViewController {
                webVC.requestUrl = url
                self.navigationController?.pushViewController(webVC, animated: true)
            }
        case 3:
            if let webKitVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "WebKitVC") as? WebKitViewController {
                webKitVC.urlString = kFormContactUrl
                self.navigationController?.pushViewController(webKitVC, animated: true)
            }
        case 4:
            performSegue(withIdentifier: "Show Settings", sender: nil)
        default: break
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}

extension MoreTableViewController {
    @objc func loggingIn(_ notification:Notification) {
        let indexPath = IndexPath(row: 1, section: 0)
        guard let cell = self.tableView.cellForRow(at: indexPath) else {
            return
        }
        
        DispatchQueue.main.async {
            cell.textLabel?.text = nil
            let activityIndicator = UIActivityIndicatorView()
            activityIndicator.color = UIColor.black
            cell.addSubview(activityIndicator)
            activityIndicator.startAnimating()
        }
    }
    @objc func loggedInSuccessfully(_ notification:Notification) {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    @objc func loginFailed(_ notification:Notification) {
        let indexPath = IndexPath(row: 1, section: 0)
        guard let cell = self.tableView.cellForRow(at: indexPath) else {
            return
        }
        
        DispatchQueue.main.async {
            for view in cell.subviews {
                if let activityIndicator = view as? UIActivityIndicatorView {
                    activityIndicator.removeFromSuperview()
                }
            }
            cell.textLabel?.text = "Login"
        }
    }
    @objc func loggedOutSuccessfully(_ notification:Notification) {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
}
