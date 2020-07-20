//
//  BFFormItem.swift
//  Bonfire
//
//  Created by James Dale on 13/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation

enum BFFormItemValue {
    case string(String)
    case int(Int)
}

struct BFFormItem<FormData: BFFormData> {
    let id = UUID()
    var path: ReferenceWritableKeyPath<FormData, BFFormItemValue?>?
    var type: BFFormItemType
    var onCompletion: () -> ()
    var validate: () -> Bool?
}

extension BFFormItem: Identifiable {}
extension BFFormItem: Equatable {
    static func == (lhs: BFFormItem, rhs: BFFormItem) -> Bool {
        lhs.id == rhs.id && lhs.type == rhs.type
    }
}
