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
            let (archived, string, foreground, background) = formattedExpiry(date: expiryDate)
            imageView.isHidden = archived
            imageView.tintColor = foreground
            label.textColor = foreground
            backgroundColor = background
            label.text = string
        }
    }

    private var stackView = UIStackView(axis: .horizontal, alignment: .center, spacing: 4)
    private var imageView = UIImageView(image: UIImage(named: "PostFireIcon"), width: 15, height: 15, contentMode: .center)
    private var label = UILabel(size: 14, weight: .bold, multiline: false, text: "?")

    init() {
        super.init(frame: .zero)
        
        constrain(self) { $0.height == 28 }
        
        layer.cornerRadius = 14
        if #available(iOS 13.0, *) { layer.cornerCurve = .continuous }
        
        stackView.layoutMargins = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(label)
        addSubview(stackView)
        constrain(stackView) {
            $0.edges == $0.superview!.edges
        }
        
//        constrain(imageView) {
//            $0.leading == $0.superview!.leading + 8
//            $0.centerY == $0.superview!.centerY
//        }
//        constrain(label, imageView) {
//            $0.leading == $1.trailing + 4
//            $0.trailing == $0.superview!.trailing - 8
//            $0.centerY == $0.superview!.centerY
//        }
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func formattedExpiry(date: Date) -> (Bool, String, UIColor, UIColor) {
        let totalSeconds = Int(date.timeIntervalSince(Date()))

        let archived: Bool = totalSeconds < 0
        var string: String
        var foreground: UIColor
        var background: UIColor

        var hours = totalSeconds / 3600
        var minutes = Int(ceil(Float(totalSeconds % 3600) / 60))

        if minutes % 60 == 0 && minutes >= 60 {
            hours += minutes / 60
            minutes = 0
        }

        if archived {
            string = "archived"
        } else if totalSeconds < 60 {
            string = "<1m"
        } else if hours == 0 {
            string = "\(minutes)m"
        } else  {
            string = "\(hours)h"
        }

        if totalSeconds < 0 {
            foreground = Constants.Color.systemBackground
            background = Constants.Color.secondary
        } else if hours > 3 {
            foreground = Constants.Color.secondary
            background = foreground.withAlphaComponent(0.1)
        } else if hours > 0 {
            foreground = .systemOrange
            background = foreground.withAlphaComponent(0.1)
        } else {
            foreground = .systemRed
            background = foreground.withAlphaComponent(0.1)
        }

        return (archived, string, foreground, background)
    }
}
