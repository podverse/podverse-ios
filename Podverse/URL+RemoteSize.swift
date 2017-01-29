//
//  URL+RemoteSize.swift
//  Podverse
//
//  Created by Creon on 12/26/16.
//  Copyright © 2016 Podverse LLC. All rights reserved.
//

import Foundation

extension URL {
    var remoteSize: Int64 {
        var contentLength: Int64 = NSURLSessionTransferSizeUnknown
        var request = URLRequest(url: self, cachePolicy: URLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData , timeoutInterval: 30.0);
        request.httpMethod = "HEAD";
        request.timeoutInterval = 5;
        let group = DispatchGroup()
        group.enter()
        URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
            contentLength = response?.expectedContentLength ?? NSURLSessionTransferSizeUnknown
            group.leave()
        }).resume()
        _ = group.wait(timeout: DispatchTime.now() + .seconds(5))
        return contentLength
    }
}
