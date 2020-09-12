//
//  NavigationButton.swift
//  Bonfire
//
//  Created by Daniel Gauthier on 2020-09-01.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit
import Cartography

enum NavigationButtonType {
    case status(emoji: String)
    case search
    case add
    case compose
    case bell
    case back
    case more
    case settings
    case custom(image: UIImage)

    var image: UIImage? {
        switch self {
        case .search:
            return UIImage(named: "SearchNavIcon")
        case .add:
            return UIImage(named: "PlusNavIcon")
        case .compose:
            return UIImage(named: "ComposeNavIcon")
        case .bell:
            return UIImage(named: "BellNavIcon")
        case .back:
            return UIImage(named: "LeftNavIcon")
        case .more:
            return UIImage(named: "MoreNavIcon")
        case .settings:
            return UIImage(named: "SettingsNavIcon")
        default:
            return nil
        }
    }
}

class NavigationButton: UIControl {

    var imageView = UIImageView(tintColor: .text)
    var label = UILabel(size: 24, weight: .bold, alignment: .center, multiline: false)
    var type: NavigationButtonType? {
        didSet {
            guard let type = type else {
                label.isHidden = true
                imageView.isHidden = true
                return
            }
            
            if case let .status(emoji) = type {
                label.isHidden = false
                imageView.isHidden = true
                label.text = emoji
            } else if case let .custom(image) = type {
                label.isHidden = true
                imageView.isHidden = false
                imageView.contentMode = .scaleAspectFill
                imageView.image = image
            } else {
                label.isHidden = true
                imageView.isHidden = false
                imageView.contentMode = .center
                imageView.image = type.image
            }
        }
    }

    init(type: NavigationButtonType? = nil) {
        defer { self.type = type }
        super.init(frame: .zero)

        constrain(self) {
            $0.width == 44
            $0.height == 44
        }

        backgroundColor = .contentGray
        layer.cornerRadius = 22
        clipsToBounds = true

        addSubview(label)
        addSubview(imageView)

        constrain(label) { $0.edges == $0.superview!.edges }
        constrain(imageView) { $0.edges == $0.superview!.edges }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
