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
    func set<Value: Any>(value: Value, forKeyPath path: ReferenceWritableKeyPath<BFFormData, Value>) {
        self[keyPath: path] = value
    }
}
