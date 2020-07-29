//
//  BFPostCell.swift
//  Bonfire
//
//  Created by James Dale on 30/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit

protocol BFPostCell: UITableViewCell {
    static var reuseIdentifier: String { get }
    static var rowHeight: CGFloat { get }
}
