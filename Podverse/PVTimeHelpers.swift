//
//  PVTimeHelpers.swift
//  Podverse
//
//  Created by Creon on 12/24/16.
//  Copyright © 2016 Podverse LLC. All rights reserved.
//

import Foundation

class PVTimeHelper {
    
    static func convertSecondsToHMS(seconds:Int) -> (Int, Int, Int) {
        let hr = seconds / 3600
        let min = (seconds % 3600) / 60
        let sec = (seconds % 3600) % 60
        
        return (hr, min, sec)
    }
    
    static func convertHMSToSeconds(hms:(Int,Int,Int)) -> Int {
        let hoursInSeconds = hms.0 * 3600
        let minutesInSeconds = hms.2 * 60
        let totalSeconds = hoursInSeconds + minutesInSeconds + hms.2
        
        return totalSeconds
    }
    
    static func convertServerDurationToNumber(durationString : String) -> NSNumber {
        var durationStringArray = durationString.components(separatedBy:":").reversed().map() { String($0) }
        var seconds = 0
        var minutes = 0
        var hours = 0
        if let secondsVal = durationStringArray.first, let secondsString = secondsVal, let sec = Int(secondsString)  {
            seconds = sec
            durationStringArray.removeFirst()
        }
        
        if let minutesVal = durationStringArray.first, let minutesString = minutesVal, let min = Int(minutesString) {
            minutes = min
            durationStringArray.removeFirst()
        }
        
        if let hoursVal = durationStringArray.first, let hoursString = hoursVal, let hr = Int(hoursString) {
            hours = hr
            durationStringArray.removeFirst()
        }
        
        return NSNumber(value:convertHMSToSeconds(hms:(hours, minutes, seconds)))
    }
    
    static func convertNumberToServerDuration (durationNSNumber : NSNumber?) -> String {
        guard let durationNumber = durationNSNumber else {
            return ""
        }
        
        let duration: Int = durationNumber.intValue
        var hours = String(duration / 3600) + ":"
        if hours == "0:" {
            hours = ""
        }
        var minutes = String((duration / 60) % 60) + ":"
        if (minutes.characters.count < 3) && (hours != "") {
            minutes = "0" + minutes
        }
        var seconds = String(duration % 60)
        if (seconds.characters.count < 2) && ((hours != "") || (minutes != "")) {
            seconds = "0" + seconds
        }
        
        return "\(hours)\(minutes)\(seconds)"
    }
}
