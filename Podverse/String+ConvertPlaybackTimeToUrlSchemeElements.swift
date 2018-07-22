//
//  String+ConvertTimeStampsToUrlSchemeElements.swift
//  Podverse
//
//  Created by Mitchell Downey on 7/22/18.
//  Copyright © 2018 Podverse LLC. All rights reserved.
//

import Foundation

extension String {
    
    func convertPlaybackTimesToUrlSchemeElements() -> String? {
        var newSelf = self
        
        do {
            let pattern = "([0-9][0-9]:[0-5][0-9]:[0-5][0-9]|[0-9]:[0-5][0-9]:[0-5][0-9]|[0-5][0-9]:[0-5][0-9]|[0-9]:[0-5][0-9])"
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let matches = regex.matches(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count))
            var indexOffset = 0
            
            for match in matches as [NSTextCheckingResult] {
                let location = match.range.location + indexOffset
                let length = match.range.length
                let range = NSMakeRange(location, length)
                if let strRange = Range(range, in: newSelf) {
                    let urlSchemeElement = convertPlaybackTimeToUrlSchemeElement(timestamp: String(newSelf[strRange]))
                    newSelf = newSelf.replacingCharacters(in: strRange, with: urlSchemeElement)
                    indexOffset += urlSchemeElement.count - length
                }
            }
        } catch {
            print(error)
        }

        return newSelf
    }
    
    private func convertPlaybackTimeToUrlSchemeElement(timestamp: String) -> String {
        return "<a href='podverse://podverse.fm?" + timestamp + "'>" + timestamp + "</a>"
    }
    
}
