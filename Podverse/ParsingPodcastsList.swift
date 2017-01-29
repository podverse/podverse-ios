//
//  ParsingPodcastsList.swift
//  Podverse
//
//  Created by Creon on 12/25/16.
//  Copyright © 2016 Podverse LLC. All rights reserved.
//

import Foundation


final class ParsingPodcastsList {
    static var shared = ParsingPodcastsList()
    var urls = [String]()
    
    var itemsParsing = 0
    
    func clearParsingPodcastsIfFinished() {
        if itemsParsing == urls.count {
            urls.removeAll()
            itemsParsing = 0
        }
    }
}
