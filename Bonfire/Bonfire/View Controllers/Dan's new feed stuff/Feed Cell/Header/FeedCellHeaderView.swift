//
//  FeedCellHeaderView.swift
//  Bonfire
//
//  Created by Daniel Gauthier on 2020-08-21.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit
import Cartography

class FeedCellHeaderView: UIView {
    var post: DummyPost! {
        didSet {
            switch post.type {
            case .liveRightNow:
                layoutIfNeeded()
                primaryImageBackingView.applyGradient(colors: [.liveTop, .liveBottom], startPoint: CGPoint(x: 0.5, y: 0), endPoint: CGPoint(x: 0.5, y: 1))
                primaryImageView.image = UIImage(named: "PostLiveIcon")
                primaryTitleLabel.text = "Live Right Now"

                [primaryImageView, primaryTitleLabel].forEach { $0.isHidden = false }
                [primaryDescriptionLabel, disclosureImageView, secondaryImageView, secondaryTitleLabel].forEach { $0.isHidden = true }

            case .post:
                guard let creator = post.people.first else { break }
                guard let camp = post.camps.first else { break }
                primaryImageView.image = creator.image
                primaryTitleLabel.text = creator.name
                secondaryImageView.image = camp.image
                secondaryTitleLabel.text = camp.name

                [primaryImageView, primaryTitleLabel, disclosureImageView, secondaryImageView, secondaryTitleLabel].forEach { $0.isHidden = false }
                primaryDescriptionLabel.isHidden = true

            case .statusUpdate:
                guard let creator = post.people.first else { break }
                primaryImageView.image = creator.image
                primaryTitleLabel.text = creator.name
                primaryDescriptionLabel.text = "updated their status"

                [primaryImageView, primaryTitleLabel, primaryDescriptionLabel].forEach { $0.isHidden = false }
                [disclosureImageView, secondaryImageView, secondaryTitleLabel].forEach { $0.isHidden = true }

            case .suggestedFriend:
                layoutIfNeeded()
                primaryImageBackingView.applyGradient(colors: [.suggestedTop, .suggestedBottom], startPoint: CGPoint(x: 0.5, y: 0), endPoint: CGPoint(x: 0.5, y: 1))
                primaryImageView.image = UIImage(named: "PostSuggestionIcon")
                primaryTitleLabel.text = "Suggested Friend"

                [primaryImageView, primaryTitleLabel].forEach { $0.isHidden = false }
                [primaryDescriptionLabel, disclosureImageView, secondaryImageView, secondaryTitleLabel].forEach { $0.isHidden = true }
            }

            if let expiry = post.expiry {
                timerButton.isHidden = false
                timerButton.expiryDate = expiry
                constrain(titleStackView, timerButton, replace: variableConstraints) {
                    $0.trailing <= $1.leading - 16
                }
            } else {
                timerButton.isHidden = true
                constrain(titleStackView, replace: variableConstraints) {
                    $0.trailing <= $0.superview!.trailing - 16
                }
            }

            if primaryDescriptionLabel.isHidden {
                titleStackView.setCustomSpacing(8, after: primaryTitleLabel)
            } else {
                titleStackView.setCustomSpacing(3, after: primaryTitleLabel)
            }
        }
    }

    private var titleStackView: UIStackView = .init(axis: .horizontal, alignment: .center, spacing: 8)
    private var primaryImageBackingView: UIView = .init(height: 24, width: 24, cornerRadius: 12)
    private var primaryImageView: UIImageView = .init(width: 24, height: 24, cornerRadius: 12, contentMode: .scaleAspectFill)
    private var primaryTitleLabel: UILabel = .init(size: 16, weight: .bold, color: .label, multiline: false)
    private var primaryDescriptionLabel: UILabel = .init(size: 16, weight: .medium, color: .secondaryLabel, multiline: false)
    private var disclosureImageView: UIImageView = .init(image: UIImage(named: "PostChevronIcon"), tintColor: .secondaryLabel, width: 5, height: 8)
    private var secondaryImageView: UIImageView = .init(width: 24, height: 24, cornerRadius: 12, contentMode: .scaleAspectFill)
    private var secondaryTitleLabel: UILabel = .init(size: 16, weight: .bold, color: .label, multiline: false)
    private var timerButton = TimerButton()

    private var variableConstraints = ConstraintGroup()

    init() {
        super.init(frame: .zero)
        setUpTitleStackView()
        setUpTimerButton()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpTitleStackView() {
        addSubview(titleStackView)
        constrain(titleStackView) {
            $0.top == $0.superview!.top + 16
            $0.leading == $0.superview!.leading + 16
            $0.bottom == $0.superview!.bottom - 10
        }

        constrain(titleStackView, replace: variableConstraints) {
            $0.trailing == $0.superview!.trailing - 16
        }

        primaryImageBackingView.addSubview(primaryImageView)
        constrain(primaryImageView) { $0.edges == $0.superview!.edges }

        [primaryImageBackingView, primaryTitleLabel, primaryDescriptionLabel, disclosureImageView, secondaryImageView, secondaryTitleLabel].forEach {
            titleStackView.addArrangedSubview($0)
        }

        primaryTitleLabel.setContentCompressionResistancePriority(.init(1000), for: .horizontal)
        primaryDescriptionLabel.setContentCompressionResistancePriority(.init(999), for: .horizontal)
        secondaryTitleLabel.setContentCompressionResistancePriority(.init(998), for: .horizontal)
    }

    private func setUpTimerButton() {
        addSubview(timerButton)
        constrain(timerButton) {
            $0.top == $0.superview!.top + 16
            $0.trailing == $0.superview!.trailing - 16
        }
    }
}
