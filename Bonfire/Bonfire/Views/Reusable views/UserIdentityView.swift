//
//  UserIdentityView.swift
//  Bonfire
//
//  Created by Daniel Gauthier on 2020-09-09.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import BFCore
import Cartography
import UIKit

class UserIdentityView: UIView {

    enum TextColor {
        case standard
        case light
        case colored
    }

    var user: User! {
        didSet {
            nameLabel.text = String(htmlEncodedString: user.attributes.displayName)

            if let emoji = user.attributes.statusEmoji {
                statusEmojiLabel.isHidden = false
                statusEmojiLabel.text = emoji
            } else {
                statusEmojiLabel.isHidden = true
            }

            verifiedImageView.isHidden = !(user.attributes.verified ?? false) || !shouldDisplayVerificationBadge

            if textColor == .colored {
                nameLabel.textColor = user.attributes.uiColor
            }
        }
    }

    var textColor: TextColor = .standard {
        didSet {
            switch textColor {
                case .standard: nameLabel.textColor = Constants.Color.primary
                case .light: nameLabel.textColor = Constants.Color.secondary
                case .colored: nameLabel.textColor = user.attributes.uiColor
            }
        }
    }

    var font: UIFont = UIFont.systemFont(ofSize: 17, weight: .bold).rounded() {
        didSet {
            nameLabel.font = font
            statusEmojiLabel.font = font
        }
    }

    var shouldDisplayVerificationBadge = true {
        didSet {
            verifiedImageView.isHidden = !shouldDisplayVerificationBadge
        }
    }

    private let nameLabel = UILabel(size: 17, weight: .bold, multiline: false)
    private let statusEmojiLabel = UILabel(size: 17, weight: .bold, multiline: false)
    private let verifiedImageView = UIImageView(image: UIImage(named: "VerifiedIcon"), width: 16, height: 16)
    private let stackView = UIStackView(axis: .horizontal, alignment: .center, spacing: 4)

    init(textColor: TextColor = .standard, font: UIFont = UIFont.systemFont(ofSize: 17, weight: .bold).rounded(), shouldDisplayVerificationBadge: Bool = true) {
        super.init(frame: .zero)
        backgroundColor = .clear

        addSubview(stackView)
        constrain(stackView) {
            $0.edges == $0.superview!.edges
        }

        stackView.addArrangedSubview(nameLabel)
        stackView.addArrangedSubview(statusEmojiLabel)
        stackView.addArrangedSubview(verifiedImageView)

        nameLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        statusEmojiLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        verifiedImageView.setContentCompressionResistancePriority(.required, for: .horizontal)

        nameLabel.allowsDefaultTighteningForTruncation = true

        defer {
            self.textColor = textColor
            self.font = font
            self.shouldDisplayVerificationBadge = shouldDisplayVerificationBadge
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
