//
//  BFTextField.swift
//  Bonfire
//
//  Created by James Dale on 21/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit

final class BFTextField: UITextField {

    init() {
        super.init(frame: .zero)

        backgroundColor = Constants.Color.pillBackground
        textColor = Constants.Color.primary
        font = UIFont.systemFont(ofSize: 20, weight: .semibold).rounded()

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.12
        layer.shadowOffset = .init(width: 0, height: 1)
        layer.shadowRadius = 2
        layer.cornerRadius = 14
        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale
        layer.masksToBounds = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.sublayers?.forEach { (sublayer) in
            sublayer.shadowPath = UIBezierPath(rect: bounds).cgPath
        }
    }

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: .init(top: 16, left: 16, bottom: 16, right: 16))
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return textRect(forBounds: bounds)
    }
}
