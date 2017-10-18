//
//  Utilities.swift
//  Podverse
//
//  Created by Mitchell Downey on 10/17/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

import Foundation

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
