//
//  Date+Formatters.swift
//  Podverse
//
//  Created by Creon on 12/29/16.
//  Copyright © 2016 Podverse LLC. All rights reserved.
//

import Foundation

extension Date {
    func toShortFormatString() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: self)
    }
}
