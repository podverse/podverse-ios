//
//  SettingsTableViewController.swift
//  Podverse
//
//  Created by Mitchell Downey on 7/3/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController {

    @IBOutlet weak var allowCellularDataLabel: UILabel!
    @IBOutlet weak var allowCellularDataSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Settings"
        self.tableView.alwaysBounceVertical = false
        
        self.allowCellularDataSwitch.isOn = UserDefaults.standard.bool(forKey: kAllowCellularDataDownloads)
        
    }
    
    @IBAction func allowCellularDataAction(_ sender: Any) {
        UserDefaults.standard.set(allowCellularDataSwitch.isOn, forKey: kAllowCellularDataDownloads)
    }
    
}
