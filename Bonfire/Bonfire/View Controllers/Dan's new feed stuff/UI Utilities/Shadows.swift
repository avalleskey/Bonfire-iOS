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
}

public extension UIView {
    func applyShadow(explicitPath: Bool = true, intensity: ShadowIntensity = .medium) {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0.5, height: 1.0)
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
        }

        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale
        if explicitPath {
            layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: layer.cornerRadius).cgPath
        }
    }

    func applyCustomShadow(path: UIBezierPath, intensity: ShadowIntensity = .medium) {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0.5, height: 1.0)
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
        }

        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale
        layer.shadowPath = path.cgPath
    }

    func removeShadow() {
        layer.shadowOpacity = 0.0
    }
}


