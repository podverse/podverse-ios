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
    let syncLabelText = "Sync podcasts"
    
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
        NotificationCenter.default.addObserver(self, selector: #selector(self.finishedSyncing(_:)), name: NSNotification.Name(rawValue: kFinishedAllParsingPodcasts), object: nil)
    }
    
    fileprivate func removeObservers() {
        NotificationCenter.default.removeObserver(self, name: .loggingIn, object: nil)
        NotificationCenter.default.removeObserver(self, name: .loggedInSuccessfully, object: nil)
        NotificationCenter.default.removeObserver(self, name: .loginFailed, object: nil)
        NotificationCenter.default.removeObserver(self, name: .loggedOutSuccessfully, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: kFinishedAllParsingPodcasts), object: nil)
    }
    
}

extension MoreTableViewController:UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Features"
        } else {
            return "Podverse"
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            if let _ = UserDefaults.standard.string(forKey: "idToken") {
                return 4
            } else {
                return 3
            }
        } else {
            return 2
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let section = indexPath.section
        let row = indexPath.row
        
        if section == 0 {
            if row == 0 {
                cell.textLabel?.text = "Playlists"
            } else if row == 1 {
                cell.textLabel?.text = "Settings"
            } else if row == 2 {
                if let _ = UserDefaults.standard.string(forKey: "idToken") {
                    cell.textLabel?.text = "Log out"
                } else {
                    cell.textLabel?.text = "Log in"
                }
            } else {
                cell.textLabel?.text = self.syncLabelText
            }
        } else {
            if row == 0 {
                cell.textLabel?.text = "Feedback"
            } else {
                cell.textLabel?.text = "About"
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let section = indexPath.section
        let row = indexPath.row
        
        if section == 0 {
            if row == 0 {
                performSegue(withIdentifier: "Show Playlists", sender: nil)
            } else if row == 1 {
                performSegue(withIdentifier: "Show Settings", sender: nil)
            } else if row == 2 {
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
            } else {
                guard let cell = self.tableView.cellForRow(at: indexPath) else {
                    return
                }
                Podcast.syncSubscribedPodcastsWithServer()
                cell.textLabel?.text = "Syncing with server..."
            }
        } else {
            if row == 0 {
                if let url = URL(string: BASE_URL + "about"), let webVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AboutVC") as? AboutViewController {
                    webVC.requestUrl = url
                    self.navigationController?.pushViewController(webVC, animated: true)
                }
            } else {
                if let webKitVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "WebKitVC") as? WebKitViewController {
                    webKitVC.urlString = kFormContactUrl
                    self.navigationController?.pushViewController(webKitVC, animated: true)
                }
            }
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
        
        cell.textLabel?.text = nil
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.color = UIColor.black
        cell.addSubview(activityIndicator)
        activityIndicator.startAnimating()
    }
    
    @objc func loggedInSuccessfully(_ notification:Notification) {
        self.tableView.reloadData()
    }
    
    @objc func loginFailed(_ notification:Notification) {
        let indexPath = IndexPath(row: 1, section: 0)
        guard let cell = self.tableView.cellForRow(at: indexPath) else {
            return
        }
        
        for view in cell.subviews {
            if let activityIndicator = view as? UIActivityIndicatorView {
                activityIndicator.removeFromSuperview()
            }
        }
        cell.textLabel?.text = "Login"
    }
    
    @objc func loggedOutSuccessfully(_ notification:Notification) {            self.tableView.reloadData()
    }
    
    @objc func finishedSyncing(_ notification:Notification) {
        let indexPath = IndexPath(row: 5, section: 0)
        guard let cell = self.tableView.cellForRow(at: indexPath) else {
            return
        }
        
        DispatchQueue.main.async {
            cell.textLabel?.text = self.syncLabelText
        }
    }
}
