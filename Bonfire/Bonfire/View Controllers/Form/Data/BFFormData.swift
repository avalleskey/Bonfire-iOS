//
//  BFFormData.swift
//  Bonfire
//
//  Created by James Dale on 20/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation

protocol BFFormData: class {
    
}

extension BFFormData {
    func set(value: BFFormItemValue, forKeyPath path: ReferenceWritableKeyPath<Self, BFFormItemValue?>) {
        self[keyPath: path] = value
    }
}
