//
//  BFSegmentedControlItem.swift
//  Bonfire
//
//  Created by James Dale on 22/6/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation

struct BFSegmentedControlItem {
    let title: String
    let target: AnyObject?
    let action: Selector?
}

extension BFSegmentedControlItem: Hashable {
    static func == (lhs: BFSegmentedControlItem, rhs: BFSegmentedControlItem) -> Bool {
        lhs.hashValue == rhs.hashValue
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(action)
    }
}
