//
//  UIViewController+InternetRequiredAlert.swift
//  Podverse
//
//  Created by Creon on 12/26/16.
//  Copyright © 2016 Podverse LLC. All rights reserved.
//

import UIKit

extension UIViewController {
    func showInternetNeededAlertWithDescription(message: String) {
        let internetNeededAlert = PVReachability.shared.createInternetConnectionNeededAlertWithDescription(message)
        DispatchQueue.main.async {
            self.present(internetNeededAlert, animated: true, completion: nil)
        }
    }
}
