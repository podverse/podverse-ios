//
//  UIViewController+AllowCellularDataDownloadsAlert.swift
//  Podverse
//
//  Created by Mitchell Downey on 2/19/18.
//  Copyright © 2018 Podverse LLC. All rights reserved.
//

import UIKit

extension UIViewController {
    func showAllowCellularDataAlert(completion: ((Bool) -> ())? = nil) {
        if !UserDefaults.standard.bool(forKey: kAskedToAllowCellularDataDownloads) {
            
            UserDefaults.standard.set(true, forKey: kAskedToAllowCellularDataDownloads)
            
            let allowCellularDataAlert = UIAlertController(title: "Enable Cellular Data?", message: "Do you want to allow downloading episodes using cellular data when not connected to Wi-Fi?", preferredStyle: UIAlertControllerStyle.alert)
            
            allowCellularDataAlert.addAction(UIAlertAction(title: "Yes", style: .default) { (_) -> Void in
                UserDefaults.standard.set(true, forKey: kAllowCellularDataDownloads)
                completion?(true)
            })
            
            allowCellularDataAlert.addAction(UIAlertAction(title: "No", style: .cancel) { (_) -> Void in
                UserDefaults.standard.set(false, forKey: kAllowCellularDataDownloads)
                completion?(false)
            })
            
            DispatchQueue.main.async {
                self.present(allowCellularDataAlert, animated: true, completion: nil)
            }
        }
    }
}
