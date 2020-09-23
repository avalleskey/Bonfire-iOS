//
//  BFActionButton.swift
//  Bonfire
//
//  Created by James Dale on 6/8/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit

final class BFActionButton: BFBouncyButton {

    enum Style {
        case primary(color: UIColor)
        case secondary(color: UIColor)
        case inset(color: UIColor)
        case none
    }
    
    var style: Style = .none {
        didSet {
            switch style {
                case .primary(let color):
                    let isDark = color.isDarkColor
                    tintColor = color
                    setTitleColor(color, for: .normal)
                    setTitleColor(color.withAlphaComponent(0.5), for: .disabled)
                    backgroundColor = isDark ? .white : .black
                    layer.shadowColor = (isDark ? UIColor.black : UIColor.white).cgColor
                    layer.borderColor = UIColor(white: 1, alpha: 0.03).cgColor
                case .secondary(let color):
                    let isDark = color.isDarkColor
                    tintColor = .white
                    setTitleColor(.white, for: .normal)
                    setTitleColor(UIColor(white: 1, alpha: 0.5), for: .disabled)
                    backgroundColor = isDark ? UIColor(white: 1, alpha: 0.2) : UIColor(white: 0, alpha: 0.12)
                    layer.shadowColor = (isDark ? UIColor.black : UIColor.white).cgColor
                    layer.borderColor = (isDark ? UIColor.white : UIColor.black).withAlphaComponent(0.03).cgColor
                case .inset(let color):
                    let isDark = color.isDarkColor
                    tintColor = isDark ? .white : .black
                    setTitleColor(tintColor, for: .normal)
                    setTitleColor(tintColor.withAlphaComponent(0.5), for: .disabled)
                    backgroundColor = (isDark ? UIColor.black : UIColor.white).withAlphaComponent(0.2)
                    layer.shadowColor = (isDark ? UIColor.white : UIColor.black).cgColor
                    layer.borderColor = (isDark ? UIColor.black : UIColor.white).withAlphaComponent(0.03).cgColor
                case .none:
                    break
            }
        }
    }

    init(style: Style) {
        self.style = style
        super.init(frame: .zero)
        
        adjustsImageWhenHighlighted = false
        titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold).rounded()
        if #available(iOS 13.0, *) {
            layer.cornerCurve = .continuous
        }
        layer.cornerRadius = 14
        layer.borderWidth = 2
        layer.masksToBounds = false
        imageEdgeInsets.right = 6
        titleEdgeInsets.left = 6
        
        applyShadow(intensity: .sketch(color: .black, alpha: 0.12, x: 0, y: 1, blur: 3, spread: 0))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
