//
//  SuggestionBadgeView.swift
//  Bonfire
//
//  Created by Daniel Gauthier on 2020-09-10.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Cartography
import UIKit

class SuggestionBadgeView: UIView {

    private let gradientView = UIView(backgroundColor: .white, height: 32, width: 32, cornerRadius: 16)
    private let imageView = UIImageView(image: UIImage(named: "SuggestionIconLarge"), contentMode: .center)

    init() {
        super.init(frame: .zero)
        backgroundColor = .white

        constrain(self) {
            $0.width == 32
            $0.height == 32
        }

        addSubview(gradientView)
        constrain(gradientView) {
            $0.center == $0.superview!.center
        }

        addSubview(imageView)
        constrain(imageView) {
            $0.edges == $0.superview!.edges
        }

        layer.cornerRadius = 16
        applyShadow(intensity: .sketch(color: .black, alpha: 0.12, x: 0, y: 1, blur: 3, spread: 0))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientView.applyGradient(colors: [.suggestedTop, .suggestedBottom], startPoint: CGPoint(x: 0.5, y: 0), endPoint: CGPoint(x: 0.5, y: 1))
    }
}
