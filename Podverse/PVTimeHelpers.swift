//
//  PVTimeHelpers.swift
//  Podverse
//
//  Created by Creon on 12/24/16.
//  Copyright © 2016 Podverse LLC. All rights reserved.
//

import Foundation

class PVTimeHelper {
    
    static func convertIntToHMSString (time : Int?) -> String {
        guard let time = time else {
            return ""
        }
        
        var hours = String(time / 3600) + ":"
        if hours == "0:" {
            hours = ""
        }
        var minutes = String((time / 60) % 60) + ":"
        if minutes.count < 3 && hours != "" {
            minutes = "0" + minutes
        }
        var seconds = String(time % 60)
        if seconds.count < 2 && (hours != "" || minutes != "") {
            seconds = "0" + seconds
        }
        
        return "\(hours)\(minutes)\(seconds)"
    }
    
    static func convertHMSStringToInt(hms : String) -> Int {
        var hmsComponents = hms.components(separatedBy:":").reversed().map() { String($0) }
        var seconds = 0
        var minutes = 0
        var hours = 0
        if let secondsVal = hmsComponents.first, let sec = Int(secondsVal)  {
            seconds = sec
            hmsComponents.removeFirst()
        }
        
        if let minutesVal = hmsComponents.first, let min = Int(minutesVal) {
            minutes = min
            hmsComponents.removeFirst()
        }
        
        if let hoursVal = hmsComponents.first, let hr = Int(hoursVal) {
            hours = hr
            hmsComponents.removeFirst()
        }
        
        return convertHMSIntsToSeconds(hms:(hours, minutes, seconds))
    }
    
    
    static func convertIntToHMSInts (seconds : Int) -> (Int, Int, Int) {
        return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }
    
    static func convertHMSIntsToSeconds(hms:(Int,Int,Int)) -> Int {
        let hoursInSeconds = hms.0 * 3600
        let minutesInSeconds = hms.2 * 60
        let totalSeconds = hoursInSeconds + minutesInSeconds + hms.2
        
        return totalSeconds
    }
    
    static func convertIntToReadableHMSDuration(seconds: Int) -> String {
        var string = ""
        let hmsInts = convertIntToHMSInts(seconds: seconds)
        
        if hmsInts.0 > 0 {
            string += String(hmsInts.0) + "h "
        }
        
        if hmsInts.1 > 0 {
            string += String(hmsInts.1) + "m "
        }
        
        if hmsInts.2 > 0 {
            string += String(hmsInts.2) + "s"
        }
        
        return string.trimmingCharacters(in: .whitespaces)
    }
        
}
