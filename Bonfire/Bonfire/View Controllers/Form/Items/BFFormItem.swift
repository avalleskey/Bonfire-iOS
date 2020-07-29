//
//  BFFormItem.swift
//  Bonfire
//
//  Created by James Dale on 13/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import CoreGraphics
import Foundation

enum BFFormItemValue {
    case string(String)
    case int(Int)
    case date(Date)
    case data(Data)
    case color(CGColor)

    var stringValue: String? {
        switch self {
        case .string(let str):
            return str
        default:
            return nil
        }
    }
}

struct BFFormItem<FormData: BFFormData> {
    let id = UUID()
    let path: ReferenceWritableKeyPath<FormData, BFFormItemValue?>?
    let type: BFFormItemType
    let instructionText: String?
    let placeholderText: String?
    let onCompletion: () -> Void
    let validate: ((BFFormItemValue, ((Result<Bool, Error>) -> ())) -> Void)
}

extension BFFormItem: Identifiable {}

extension BFFormItem: Equatable {
    static func == (lhs: BFFormItem, rhs: BFFormItem) -> Bool {
        lhs.id == rhs.id && lhs.type == rhs.type
    }
}
