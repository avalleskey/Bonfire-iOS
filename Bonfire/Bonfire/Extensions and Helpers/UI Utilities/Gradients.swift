//
//  Gradients.swift
//  Bonfire
//
//  Created by Daniel Gauthier on 2020-08-24.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit

extension UIView {
    func applyGradient(colors: [UIColor], startPoint: CGPoint = CGPoint(x: 0, y: 1), endPoint: CGPoint = CGPoint(x: 1, y: 0)) {
        let gradient = CAGradientLayer()
        gradient.frame = bounds
        gradient.colors = colors.map { $0.cgColor }
        gradient.startPoint = startPoint
        gradient.endPoint = endPoint
        layer.sublayers?.forEach {
            if $0 is CAGradientLayer {
                $0.removeFromSuperlayer()
            }
        }
        layer.insertSublayer(gradient, at: 0)
        layer.masksToBounds = true
    }

    func removeGradient() {
        layer.sublayers?.forEach {
            if $0 is CAGradientLayer {
                $0.removeFromSuperlayer()
            }
        }
    }
}
