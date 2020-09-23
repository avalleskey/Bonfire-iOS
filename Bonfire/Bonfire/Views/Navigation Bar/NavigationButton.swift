//
//  NavigationButton.swift
//  Bonfire
//
//  Created by Daniel Gauthier on 2020-09-01.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit
import Cartography

enum NavigationButtonType: Equatable {
    case back
    case close
    case status(emoji: String)
    case search
    case add
    case compose
    case bell
    case more
    case settings
    case custom(image: UIImage)

    var image: UIImage? {
        switch self {
        case .back:
            return UIImage(named: "LeftNavIcon")
        case .close:
            return UIImage(named: "CloseNavIcon")
        case .search:
            return UIImage(named: "SearchNavIcon")
        case .add:
            return UIImage(named: "PlusNavIcon")
        case .compose:
            return UIImage(named: "ComposeNavIcon")
        case .bell:
            return UIImage(named: "BellNavIcon")
        case .more:
            return UIImage(named: "MoreNavIcon")
        case .settings:
            return UIImage(named: "SettingsNavIcon")
        default:
            return nil
        }
    }
}

class NavigationButton: BFShadedButton {
    
    var label = UILabel(size: 24, weight: .bold, alignment: .center, multiline: false)
    var type: NavigationButtonType? {
        didSet {
            guard let type = type else {
                label.isHidden = true
                imageView?.isHidden = true
                return
            }
            
            if case let .status(emoji) = type {
                label.isHidden = false
                setImage(nil, for: .normal)
                label.text = emoji
            } else if case let .custom(image) = type {
                label.isHidden = true
                setImage(image, for: .normal)
                contentMode = .center
            } else {
                label.isHidden = true
                setImage(type.image, for: .normal)
                contentMode = .center
            }
        }
    }

    init(type: NavigationButtonType? = nil) {
        defer { self.type = type }
        super.init(frame: .zero)
        
        let diameter: CGFloat = 42

        constrain(self) {
            $0.width == diameter
            $0.height == diameter
        }

        layer.cornerRadius = diameter / 2
        clipsToBounds = true

        addSubview(label)
        constrain(label) { $0.edges == $0.superview!.edges }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = frame.width / 2
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
