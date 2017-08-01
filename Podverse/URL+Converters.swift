//
//  URL+Converters.swift
//  Podverse
//
//  Created by Mitchell Downey on 8/1/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

import Foundation

extension URL {
    
    func convertToCustomUrl(scheme: String) -> URL? {

        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else { return nil }
        
        if self.absoluteString.hasPrefix("http://") {
            components.scheme = "http" + scheme
        } else {
            components.scheme = "https" + scheme
        }
        
        return components.url
        
    }

    func convertToOriginalUrl() -> URL? {
        
        let actualUrlComponents = NSURLComponents(url: self, resolvingAgainstBaseURL: false)
        
        if self.scheme == "httpstreaming" {
            actualUrlComponents?.scheme = "http"
        } else if self.scheme == "httpsstreaming" {
            actualUrlComponents?.scheme = "https"
        }
        
        return actualUrlComponents?.url
        
    }
    
}

