//
//  Array+rearrange.swift
//  Podverse
//
//  Created by Mitchell Downey on 7/2/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

import Foundation

extension Array { // thanks Leo Dabus https://stackoverflow.com/a/36542411/2608858
    mutating func rearrange(from: Int, to: Int) {
        if (from == to) { return }
        precondition(indices.contains(from) && indices.contains(to), "invalid indexes")
        insert(remove(at: from), at: to)
    }
}
