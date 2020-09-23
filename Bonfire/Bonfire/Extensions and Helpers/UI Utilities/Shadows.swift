//
//  Shadows.swift
//  Bonfire
//
//  Created by Daniel Gauthier on 2020-08-19.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit

public enum ShadowIntensity {
    case none
    case light
    case medium
    case heavy
    case diffuse
    case sketch(color: UIColor, alpha: Float, x: CGFloat, y: CGFloat, blur: CGFloat, spread: CGFloat)
}

public extension UIView {
    func applyShadow(explicitPath: Bool = true, intensity: ShadowIntensity = .medium) {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0.5, height: 1.0)
        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale
        if explicitPath {
            layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: layer.cornerRadius).cgPath
        }

        switch intensity {
        case .none:
            layer.shadowOpacity = 0
            layer.shadowRadius = 2.0
        case .light:
            layer.shadowOpacity = 0.04
            layer.shadowRadius = 2.0
        case .medium:
            layer.shadowOpacity = 0.07
            layer.shadowRadius = 2.0
        case .heavy:
            layer.shadowOpacity = 0.2
            layer.shadowRadius = 2.0
        case .diffuse:
            layer.shadowOpacity = 0.07
            layer.shadowRadius = 8.0
        case let .sketch(color, alpha, x, y, blur, spread):
            layer.shadowColor = color.cgColor
            layer.shadowOpacity = alpha
            layer.shadowOffset = CGSize(width: x, height: y)
            layer.shadowRadius = blur / 2.0
            if spread == 0 {
                layer.shadowPath = nil
            } else {
                let pathRect = bounds.insetBy(dx: -spread, dy: -spread)
                layer.shadowPath = UIBezierPath(rect: pathRect).cgPath
            }
        }
    }

    func applyCustomShadow(path: UIBezierPath, intensity: ShadowIntensity = .medium) {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0.5, height: 1.0)
        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale
        layer.shadowPath = path.cgPath
        switch intensity {
        case .none:
            layer.shadowOpacity = 0
            layer.shadowRadius = 2.0
        case .light:
            layer.shadowOpacity = 0.04
            layer.shadowRadius = 2.0
        case .medium:
            layer.shadowOpacity = 0.07
            layer.shadowRadius = 2.0
        case .heavy:
            layer.shadowOpacity = 0.2
            layer.shadowRadius = 2.0
        case .diffuse:
            layer.shadowOpacity = 0.07
            layer.shadowRadius = 8.0
        case let .sketch(color, alpha, x, y, blur, spread):
            layer.shadowColor = color.cgColor
            layer.shadowOpacity = alpha
            layer.shadowOffset = CGSize(width: x, height: y)
            layer.shadowRadius = blur / 2.0
            if spread == 0 {
                layer.shadowPath = nil
            } else {
                let pathRect = bounds.insetBy(dx: -spread, dy: -spread)
                layer.shadowPath = UIBezierPath(rect: pathRect).cgPath
            }
        }
    }

    func removeShadow() {
        layer.shadowOpacity = 0.0
    }
}


