//
//  Cells.swift
//  Bonfire
//
//  Created by Daniel Gauthier on 2020-08-24.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit

extension UITableViewCell {
    static var reuseIdentifier: String { String(describing: self) }
}

extension UICollectionViewCell {
    static var reuseIdentifier: String { String(describing: self) }
}
