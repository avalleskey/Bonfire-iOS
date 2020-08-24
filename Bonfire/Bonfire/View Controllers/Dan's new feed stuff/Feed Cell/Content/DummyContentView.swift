//
//  DummyContentView.swift
//  Bonfire
//
//  Created by Daniel Gauthier on 2020-08-21.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit
import Cartography

class DummyContentView: UIView {

    private let rectangleView = UIView(backgroundColor: UIColor(hex: "8E8E93")!.withAlphaComponent(0.1), height: 200, cornerRadius: 14)
    private let label = UILabel(size: 16, weight: .bold, color: .tertiaryLabel, text: "Content")

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
