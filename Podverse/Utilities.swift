//
//  Utilities.swift
//  Podverse
//
//  Created by Mitchell Downey on 10/17/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

import Foundation
import UIKit

func checkForConnectivity() -> Bool {
    
    guard PVReachability.shared.hasInternetConnection() else {
        return false
    }
    
    return true
    
}

func checkForResults(results: [Any]?) -> Bool {
    
    guard let results = results, results.count > 0 else {
        return false
    }
    
    return true
    
}

func showNetworkActivityIndicator() {
    DispatchQueue.main.async {
        (UIApplication.shared.delegate as? AppDelegate)?.networkCounter += 1
    }
}

func hideNetworkActivityIndicator() {
    DispatchQueue.main.async {
        (UIApplication.shared.delegate as? AppDelegate)?.networkCounter -= 1
    }
}

