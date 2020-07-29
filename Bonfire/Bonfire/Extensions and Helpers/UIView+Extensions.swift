//
//  UIView+Extensions.swift
//  Bonfire
//
//  Created by James Dale on 21/6/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit

extension UIView {
    func round(corners: CACornerMask, radius: CGFloat) {
        layer.cornerRadius = radius
        layer.maskedCorners = corners
    }

    func smoothRound(radius: CGFloat) {
        let mask = CAShapeLayer()
        mask.frame = bounds
        mask.path = UIBezierPath(roundedRect: bounds, cornerRadius: radius).cgPath
        layer.mask = mask
    }
}

extension UIView {
    func shake() {
        self.transform = CGAffineTransform(translationX: 20, y: 0)
        UIView.animate(
            withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.2, initialSpringVelocity: 1,
            options: .curveEaseInOut,
            animations: {
                self.transform = CGAffineTransform.identity
            }, completion: nil)
    }
}
