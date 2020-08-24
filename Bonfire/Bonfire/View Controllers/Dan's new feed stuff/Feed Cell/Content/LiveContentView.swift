//
//  LiveContentView.swift
//  Bonfire
//
//  Created by Daniel Gauthier on 2020-08-21.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit
import Cartography

class LiveContentView: UIView {

    private let rectangleView = UIView(backgroundColor: UIColor.systemPink.withAlphaComponent(0.1), height: 100, cornerRadius: 14)
    private let label = UILabel(size: 16, weight: .bold, color: .systemPink, text: "Live camps")

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
            $0.leading == $0.superview!.leading + 16
            $0.trailing == $0.superview!.trailing - 16
            $0.top == $0.superview!.top
            $0.bottom == $0.superview!.bottom - 16
        }

        rectangleView.addSubview(label)
        constrain(label) {
            $0.center == $0.superview!.center
        }
    }
}
