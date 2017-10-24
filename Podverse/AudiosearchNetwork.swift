//
//  AudiosearchNetwork.swift
//  Podverse
//
//  Created by Mitchell Downey on 10/23/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

import Foundation

class AudiosearchNetwork {
    
    var id:Int64?
    var name:String?
    
    static func convertJSONToAudiosearchNetworks(_ json: AnyObject) -> [AudiosearchNetwork]? {
        
        var networks = [AudiosearchNetwork]()
        
        if let items = json as? [AnyObject] {
            for item in items {
                let network = AudiosearchNetwork()
                network.id = item["id"] as? Int64
                network.name = item["name"] as? String
                networks.append(network)
            }
        }
        
        return networks
        
    }
    
    static func retrieveNetworksFromServer(_ completion: @escaping (_ networks:[AudiosearchNetwork]?) -> Void) {
        
        AudioSearchClientSwift.retrieveNetworks({ serviceResponse in
            
            if let response = serviceResponse.0, let networks = AudiosearchNetwork.convertJSONToAudiosearchNetworks(response) {
                completion(networks)
            }
            
            if let error = serviceResponse.1 {
                print(error.localizedDescription)
                completion(nil)
            }
            
        })
        
    }
    
}
