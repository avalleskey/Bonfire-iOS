//
//  SuggestionContentView.swift
//  Bonfire
//
//  Created by Daniel Gauthier on 2020-08-21.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit
import Cartography

class SuggestionContentView: UIView {

    private let rectangleView = UIView(backgroundColor: UIColor.systemTeal, height: 170, cornerRadius: 14)
    private let label = UILabel(size: 16, weight: .bold, color: .white, text: "Abayo Stevens")

    init() {
        super.init(frame: .zero)
        setUpRectangleView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpRectangleView() {
        addSubview(rectangleView)
        constrain(rectangleView) {
            $0.edges == inset($0.superview!.edges, horizontally: 16)
        }

        rectangleView.addSubview(label)
        constrain(label) {
            $0.center == $0.superview!.center
        }
    }
}
