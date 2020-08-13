//
//  User+Extensions.swift
//  Bonfire
//
//  Created by James Dale on 14/8/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import BFCore
import UIKit

extension User.Attributes {
    var uiColor: UIColor? {
        UIColor(hex: color)
    }
}
