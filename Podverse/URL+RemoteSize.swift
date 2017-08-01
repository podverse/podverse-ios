//
//  URL+RemoteSize.swift
//  Podverse
//
//  Created by Creon on 12/26/16.
//  Copyright © 2016 Podverse LLC. All rights reserved.
//

import Foundation

extension URL {
    func remoteSize() {
        var contentLength: Int64 = NSURLSessionTransferSizeUnknown
        var request = URLRequest(url: self, cachePolicy: URLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData , timeoutInterval: 30.0);
        
        // I originally tried to derive expectedContentLength using httpMethod of "HEAD", but discovered that, while it worked for most podcsats, some nginx servers do not include Content Length in a response header.
        
        // Pod Save America is the podcast I discovered this issue with. Attempt to make a HEAD request with this link for an example https://rss.art19.com/episodes/92be9331-1cd4-4f93-88c7-c1f3139f2807.mp3
        
        // In order to work around this issue, I'm using a GET request instead, then overriding the NSURLSessionDataDelegate in PVStreamer to determine the content length, then immediately cancel the session for that GET request.
        
        request.httpMethod = "GET";
        request.timeoutInterval = 5;
        let group = DispatchGroup()
        group.enter()
        
        URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
            group.leave()
        }).resume()
        _ = group.wait(timeout: DispatchTime.now() + .seconds(5))
    }
}
