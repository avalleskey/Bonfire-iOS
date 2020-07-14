//
//  BFFormItem.swift
//  Bonfire
//
//  Created by James Dale on 13/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation

struct BFFormItem {
    var path: AnyKeyPath?
    var type: BFFormItemType
    var onCompletion: () -> ()
    var validate: () -> Bool?
}
