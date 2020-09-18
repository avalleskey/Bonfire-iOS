//
//  PushTransition.swift
//  Bonfire
//
//  Created by Austin Valleskey on 9/17/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit

struct PushTransition {
    struct Constants {
        static let pushDuration: Double = 0.5
        static let pushDamping: CGFloat = 0.9
        static let popDuration: Double = 0.5
        static let popDamping: CGFloat = 0.85
        
        struct FadeView {
            static let alpha: CGFloat = 0.3
        }
        struct TopView {
            static let translationMultiplier = -0.4 // along the x axis
            static let cornerRadius = UIDevice.current.hasNotch ? 38.5 : 0
        }
        struct BottomView {
            static let xTranslationMultiplier: CGFloat = -0.4
        }
    }
}

extension UIViewController {
    func prepareViewControllerForPush() {
        view.layer.cornerRadius = UIDevice.current.cornerRadius
        view.layer.masksToBounds = true
        if #available(iOS 13.0, *) {
            view.layer.cornerCurve = .continuous
        }
        view.applyShadow(intensity: .sketch(color: .black, alpha: 0.08, x: 0, y: 0, blur: 3, spread: 0))
    }
}
