//
//  AudiosearchCategory.swift
//  Podverse
//
//  Created by Mitchell Downey on 10/23/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

import Foundation

class AudiosearchCategory {
    
    var id:Int64?
    var name:String?
    var parent_id:Int64?
    
    static func convertJSONToAudiosearchCategories(_ json: AnyObject) -> [AudiosearchCategory]? {
        
        var categories = [AudiosearchCategory]()
        
        if let items = json as? [AnyObject] {
            for item in items {
                let category = AudiosearchCategory()
                category.id = item["id"] as? Int64
                category.name = item["name"] as? String
                category.parent_id = item["parent_id"] as? Int64
                categories.append(category)
            }
        }
        
        return categories
        
    }
    
    static func retrieveCategoriesFromServer(parentId: Int64?, _ completion: @escaping (_ categories:[AudiosearchCategory]?) -> Void) {

        AudioSearchClientSwift.retrieveCategories({ serviceResponse in
            if let response = serviceResponse.0, let categories = AudiosearchCategory.convertJSONToAudiosearchCategories(response) {
                completion(categories)
            }
            
            if let error = serviceResponse.1 {
                print(error.localizedDescription)
                completion(nil)
            }
            
        })
        
    }
    
    static func filterCategories(categories: [AudiosearchCategory] , parentId: Int64?) -> [AudiosearchCategory] {
        
        var filteredCategories = [AudiosearchCategory]()
        
        if let parentId = parentId {
            filteredCategories = categories.filter { $0.parent_id == parentId }
        } else {
            filteredCategories = categories.filter { $0.parent_id == nil }
        }
        
        // TODO: how can we do this without force unwrapping?
        filteredCategories.sort(by: { $0.name! < $1.name! })

        return filteredCategories
        
    }
    
}

