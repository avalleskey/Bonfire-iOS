//
//  BFForm.swift
//  Bonfire
//
//  Created by James Dale on 13/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation

protocol BFForm {
    associatedtype DataType: BFFormData

    var data: DataType { get }
    var items: [BFFormItem<DataType>] { get }
    
    func finalize(completion: @escaping (Bool) -> ())
}
