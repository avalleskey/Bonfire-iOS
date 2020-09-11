//
//  TimerButton.swift
//  Bonfire
//
//  Created by Daniel Gauthier on 2020-08-21.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit
import Cartography

class TimerButton: UIControl {

    var expiryDate: Date! {
        didSet {
            let (string, color) = formattedExpiry(date: expiryDate)
            imageView.tintColor = color
            label.textColor = color
            backgroundColor = color.withAlphaComponent(0.1)
            label.text = string
        }
    }

    private var imageView = UIImageView(image: UIImage(named: "PostFireIcon"), width: 15, height: 15, contentMode: .center)
    private var label = UILabel(size: 14, weight: .bold, multiline: false, text: "?")

    init() {
        super.init(frame: .zero)
        constrain(self) { $0.height == 24 }
        layer.cornerRadius = 12
        if #available(iOS 13.0, *) { layer.cornerCurve = .continuous }

        addSubview(imageView)
        constrain(imageView) {
            $0.leading == $0.superview!.leading + 8
            $0.centerY == $0.superview!.centerY
        }

        addSubview(label)
        constrain(label, imageView) {
            $0.leading == $1.trailing + 4
            $0.trailing == $0.superview!.trailing - 8
            $0.centerY == $0.superview!.centerY
        }
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func formattedExpiry(date: Date) -> (String, UIColor) {
        let totalSeconds = Int(date.timeIntervalSince(Date()))

        var string: String
        var color: UIColor

        var hours = totalSeconds / 3600
        var minutes = Int(ceil(Float(totalSeconds % 3600) / 60))

        if minutes % 60 == 0 && minutes >= 60 {
            hours += minutes / 60
            minutes = 0
        }

        if totalSeconds < 60 {
            string = "<1m"
        } else if hours == 0 {
            string = "\(minutes)m"
        } else  {
            string = "\(hours)h"
        }

        if hours > 2 {
            color = .secondaryText
        } else if hours > 0 {
            color = .systemOrange
        } else {
            color = .systemRed
        }

        return (string, color)
    }
}
