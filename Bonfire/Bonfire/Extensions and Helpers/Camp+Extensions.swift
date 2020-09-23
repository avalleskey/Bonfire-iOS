//
//  Camp+Extensions.swift
//  Bonfire
//
//  Created by James Dale on 14/8/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import BFCore
import UIKit

extension Camp.Attributes {
    var uiColor: UIColor {
        UIColor(hex: color) ?? Constants.Color.secondary
    }
}
