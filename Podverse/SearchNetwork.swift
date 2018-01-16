//
//  SearchNetwork.swift
//  Podverse
//
//  Created by Mitchell Downey on 10/23/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

//import Foundation
//
//class SearchNetwork {
//    
//    var id:Int64?
//    var name:String?
//    
//    static func convertJSONToSearchNetworks(_ json: AnyObject) -> [SearchNetwork]? {
//        
//        var networks = [SearchNetwork]()
//        
//        if let items = json as? [AnyObject] {
//            for item in items {
//                let network = SearchNetwork()
//                network.id = item["id"] as? Int64
//                network.name = item["name"] as? String
//                networks.append(network)
//            }
//        }
//        
//        return networks
//        
//    }
//    
//    static func retrieveNetworksFromServer(_ completion: @escaping (_ networks:[SearchNetwork]?) -> Void) {
//        
//        SearchClientSwift.retrieveNetworks({ serviceResponse in
//            
//            if let response = serviceResponse.0, let networks = SearchNetwork.convertJSONToSearchNetworks(response) {
//                completion(networks)
//            } else if let error = serviceResponse.1 {
//                print(error.localizedDescription)
//                completion(nil)
//            }
//            
//        })
//        
//    }
//    
//}

