//
//  QuickAccessUserCell.swift
//  Bonfire
//
//  Created by Daniel Gauthier on 2020-09-09.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Cartography
import UIKit

class QuickAccessUserCell: UICollectionViewCell {

    var user: DummyPost.User! {
        didSet {
            imageView.image = user.image
            userIdentityView.user = user
            suggestionBadgeView.isHidden = !user.isSuggested
            if let lastMessage = user.lastMessage, !lastMessage.isRead {
                newDotView.isHidden = false
                newDotView.backgroundColor = user.color
                userIdentityView.textColor = .colored
                userIdentityView.font = UIFont.systemFont(ofSize: 14, weight: .heavy).rounded()
            } else {
                newDotView.isHidden = true
                userIdentityView.textColor = .light
                userIdentityView.font = UIFont.systemFont(ofSize: 14, weight: .bold).rounded()
            }
        }
    }

    private let imageContainerView = UIView(height: 96, width: 96, cornerRadius: 48)
    private let imageView = UIImageView(width: 96, height: 96, cornerRadius: 48, contentMode: .scaleAspectFill)
    private let suggestionBadgeView = SuggestionBadgeView()
    private let newDotView = UIView(height: 11, width: 11, cornerRadius: 5.5)
    private let userIdentityView = UserIdentityView(textColor: .light, font: UIFont.systemFont(ofSize: 14, weight: .bold).rounded(), shouldDisplayVerificationBadge: false)
    private let stackView = UIStackView(axis: .horizontal, alignment: .center, spacing: 4)

    override init(frame: CGRect) {
        super.init(frame: .zero)
        backgroundColor = .clear

        contentView.addSubview(imageContainerView)
        constrain(imageContainerView) {
            $0.top == $0.superview!.top
            $0.centerX == $0.superview!.centerX
        }

        imageContainerView.addSubview(imageView)
        constrain(imageView) {
            $0.center == $0.superview!.center
        }

        contentView.addSubview(suggestionBadgeView)
        constrain(suggestionBadgeView, imageContainerView) {
            $0.trailing == $1.trailing - 3
            $0.bottom == $1.bottom - 3
        }

        contentView.addSubview(stackView)
        constrain(stackView) {
            $0.bottom == $0.superview!.bottom
            $0.centerX == $0.superview!.centerX
            $0.leading >= $0.superview!.leading
            $0.trailing <= $0.superview!.trailing
        }

        stackView.addArrangedSubview(newDotView)
        stackView.addArrangedSubview(userIdentityView)

        imageContainerView.applyShadow(explicitPath: true, intensity: .sketch(color: .black, alpha: 0.08, x: 0, y: 6, blur: 14, spread: 0))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
