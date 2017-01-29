//
//  String+CharacterManipulation.swift
//  Podverse
//
//  Created by Creon on 12/27/16.
//  Copyright © 2016 Podverse LLC. All rights reserved.
//

import Foundation

extension String {
    func removeArticles() -> String {
        var words = self.components(separatedBy: " ")
        
        //Only one word so count it as sortable
        if(words.count <= 1) {
            return self
        }
        
        if( words[0].lowercased() == "a" || words[0].lowercased() == "the" || words[0].lowercased() == "an" ) {
            words.removeFirst()
            return words.joined(separator: " ")
        }
        
        return self
    }
    
    func removeHTMLFromString() -> String? {
        return self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
    }
    
    func encodePipeInString () -> String {
        return self.replacingOccurrences(of:"|", with:"%7C", options: .literal, range: nil)
    }

}
