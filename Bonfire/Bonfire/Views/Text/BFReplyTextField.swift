//
//  BFReplyTextField.swift
//  Bonfire
//
//  Created by James Dale on 7/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit

final class BFReplyTextField: UITextField {
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: .init(top: 12, left: 16, bottom: 12, right: 16))
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return textRect(forBounds: bounds)
    }
}
