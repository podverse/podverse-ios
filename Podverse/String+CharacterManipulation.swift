//
//  String+CharacterManipulation.swift
//  Podverse
//
//  Created by Creon on 12/27/16.
//  Copyright © 2016 Podverse LLC. All rights reserved.
//

import Foundation
import UIKit

extension String {
    
    func formatHtmlString(isWhiteBg: Bool = false) -> String {
        
        var style = ""
        
        if isWhiteBg {
            style = "<style>* { color: #000 !important; font-size: 16px !important; font-family: -apple-system !important; font-weight: 400 !important; } body { margin: 24px 12px !important; padding: 0 !important; } a { color: #007aff !important; text-decoration: none !important; } p { margin-top: 0 !important; } strong { font-weight: 500 !important } hr { border: none !important; height: 1px !important; color: #ccc !important; background-color: #ccc !important; } .lightGray { color: #aaa !important }</style>"
        } else {
            style = "<style>* { color: #fff !important; font-size: 16px !important; font-family: -apple-system !important; font-weight: 400 !important; } body { margin: 24px 12px !important; padding: 0 !important; } a { color: #007aff !important; text-decoration: none !important; } p { margin-top: 0 !important; } strong { font-weight: 500 !important } hr { border: none !important; height: 1px !important; color: #5d5d5d !important; background-color: #5d5d5d !important; } .lightGray { color: #aaa !important }</style>"
        }
        
        return style + self
    }
    
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
