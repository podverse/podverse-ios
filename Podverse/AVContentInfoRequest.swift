//
//  AVContentInfoRequest.swift
//  Podverse
//
//  Created by Mitchell Downey on 8/7/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

import Foundation
import AVFoundation

internal extension AVAssetResourceLoadingContentInformationRequest {
    
    func update(with response: URLResponse) {
        
        if let response = response as? HTTPURLResponse {
            
            // TODO: what should this really be?
            contentType = "public.mp3"
            
            contentLength = response.expectedContentLength
            
            if let acceptRanges = response.allHeaderFields["Accept-Ranges"] as? String, acceptRanges == "bytes" {
                isByteRangeAccessSupported = true
            } else {
                isByteRangeAccessSupported = false
            }
            
        } else {
            print("Invalid URL Response")
        }
        
    }
    
}
