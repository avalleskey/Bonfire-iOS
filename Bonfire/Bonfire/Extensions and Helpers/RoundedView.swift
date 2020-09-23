//
//  UIView.swift
//  Bonfire
//
//  Created by Austin Valleskey on 24/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation
import UIKit

class RoundedView: UIView {
    private func updateRadius() {
        layer.cornerRadius = frame.width / 2
        layer.masksToBounds = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateRadius()
    }

    override func updateConstraints() {
        super.updateConstraints()
        translatesAutoresizingMaskIntoConstraints = false
        widthAnchor.constraint(equalTo: heightAnchor).isActive = true
    }
}
