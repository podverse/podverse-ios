//
//  PVPlayerHistoryManager.swift
//  Podverse
//
//  Created by Mitchell Downey on 5/21/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

import Foundation

class PlayerHistory {
    static let manager = PlayerHistory()
    var historyItems = [PlayerHistoryItem]()
    
    //save data
    func saveData() {
        let data = NSMutableData()
        let archiver = NSKeyedArchiver(forWritingWith: data)
        archiver.encode(historyItems, forKey: "userHistory")
        archiver.finishEncoding()
        data.write(toFile: dataFilePath(), atomically: true)
    }
    
    //read data
    func loadData() {
        let path = self.dataFilePath()
        let defaultManager = FileManager()
        if defaultManager.fileExists(atPath: path) {
            let url = URL(fileURLWithPath: path)
            let data = try! Data(contentsOf: url)
            let unarchiver = NSKeyedUnarchiver(forReadingWith: data)
            historyItems = unarchiver.decodeObject(forKey: "userHistory") as! Array
            unarchiver.finishDecoding()
        }
    }
    
    func documentsDirectory()->String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                        .userDomainMask, true)
        let documentsDirectory = paths.first!
        return documentsDirectory
    }
    
    func dataFilePath ()->String{
        return self.documentsDirectory().appendingFormat("/.plist")
    }
    
    func addOrUpdateItem(item: PlayerHistoryItem) {
        print(item)
    }
}