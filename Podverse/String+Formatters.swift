//
//  String+Formatters.swift
//  Podverse
//
//  Created by Creon on 12/29/16.
//  Copyright © 2016 Podverse LLC. All rights reserved.
//

import Foundation

extension String {
    func toServerDate() -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return dateFormatter.date(from: self)
    }
}
