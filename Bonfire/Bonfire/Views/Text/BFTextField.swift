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

        backgroundColor = .white

        let shadowLayer1 = CALayer()
        shadowLayer1.shadowColor = UIColor.black.cgColor
        shadowLayer1.shadowOpacity = 0.12
        shadowLayer1.shadowOffset = .init(width: 0, height: 2)
        shadowLayer1.shadowRadius = 0

        let shadowLayer2 = CALayer()
        shadowLayer2.shadowColor = UIColor.black.cgColor
        shadowLayer2.shadowOpacity = 0.06
        shadowLayer2.shadowOffset = .init(width: 0, height: 0)
        shadowLayer2.shadowRadius = 1

        layer.masksToBounds = false
        layer.insertSublayer(shadowLayer1, at: 0)
        layer.insertSublayer(shadowLayer2, at: 1)
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
