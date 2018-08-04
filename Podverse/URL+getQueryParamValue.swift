//
//  URL+getQueryParamValue.swift
//  Podverse
//
//  Created by Mitchell Downey on 7/31/18.
//  Copyright © 2018 Podverse LLC. All rights reserved.
//

import Foundation

extension URL {
    func getQueryParamValue(_ param:String) -> String? {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: true) else {
            return nil
        }
        
        return components.queryItems?.first(where: { $0.name == param})?.value
    }
}
