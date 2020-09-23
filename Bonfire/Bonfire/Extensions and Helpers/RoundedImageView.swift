//
//  RoundedImageView.swift
//  Bonfire
//
//  Created by James Dale on 21/6/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation
import UIKit

final class RoundedImageView: UIImageView {
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
