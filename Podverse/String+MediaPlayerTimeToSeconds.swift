//
//  String+MediaPlayerTimeToSeconds.swift
//  Podverse
//
//  Created by Mitchell Downey on 7/22/18.
//  Copyright © 2018 Podverse LLC. All rights reserved.
//

import Foundation

extension String {
    func mediaPlayerTimeToSeconds() -> Int64 {
        let timeComponents = self.components(separatedBy: ":")
        var int = Int64(0)
        
        if timeComponents.count == 2, let minutes = Int64(timeComponents[0]), let seconds = Int64(timeComponents[1]) {
            int = minutes * 60 + seconds
        } else if timeComponents.count == 3, let hours = Int64(timeComponents[0]), let minutes = Int64(timeComponents[1]), let seconds = Int64(timeComponents[2])  {
            int = hours * 3600 + minutes * 60 + seconds
        }
        
        return int
    }
}
