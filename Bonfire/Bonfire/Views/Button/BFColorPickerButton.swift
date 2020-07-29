//
//  BFColorPickerButton.swift
//  Bonfire
//
//  Created by James Dale on 22/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation
import UIKit

final class BFColorPickerButton: UIButton {
    // TODO: Implement

    let color: UIColor

    init(color: UIColor) {
        self.color = color
        super.init(frame: .zero)
        backgroundColor = color
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

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
