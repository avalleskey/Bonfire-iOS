//
//  BFFormCell.swift
//  Bonfire
//
//  Created by James Dale on 18/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation
import UIKit

protocol BFFormCell: UIViewController {
    func value() -> BFFormItemValue
}
