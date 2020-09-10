//
//  FeedCellHeaderView.swift
//  Bonfire
//
//  Created by Daniel Gauthier on 2020-08-21.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import BFCore
import UIKit
import Cartography

class FeedCellHeaderView: UIView {
    var post: Post! {
        didSet {
            let creator = post.attributes.creator
            let camp = post.attributes.postedIn
            activatePostLayout()
            primaryImageView.kf.setImage(with: creator.attributes.media?.avatar?.full?.url)
            titleLabel.text = creator.attributes.display_name
            secondaryImageView.kf.setImage(with: camp?.attributes.media?.avatar?.full?.url)
            secondaryLabel.text = camp?.attributes.title
            descriptionLabel.isHidden = true
            titleLabel.textColor = creator.attributes.uiColor

            // TODO: The commented out code below worked with the DummyPost type.
            // There is work left to be done here to get other post types (live right now, suggestion, status update)
            // working with real data from the backend, but the UI should all be here and ready to plug into.

//            switch post.type {
//            case .liveRightNow:
//                activateBasicLayout()
//                DispatchQueue.main.async {
//                    self.primaryImageBackingView.applyGradient(colors: [.liveTop, .liveBottom], startPoint: CGPoint(x: 0.5, y: 0), endPoint: CGPoint(x: 0.5, y: 1))
//                }
//                primaryImageView.image = UIImage(named: "PostLiveIcon")
//                titleLabel.text = "Live Right Now"
//
//                descriptionLabel.isHidden = true
//                titleLabel.textColor = .label
//
//            case .post:
//                guard let creator = post.people.first else { break }
//                guard let camp = post.camps.first else { break }
//                activatePostLayout()
//                primaryImageView.image = creator.image
//                titleLabel.text = creator.name
//                secondaryImageView.image = camp.image
//                secondaryLabel.text = camp.name
//                descriptionLabel.isHidden = true
//                titleLabel.textColor = creator.color
//
//            case .statusUpdate:
//                guard let creator = post.people.first else { break }
//                activateBasicLayout()
//                primaryImageView.image = creator.image
//                titleLabel.text = creator.name
//                descriptionLabel.text = "updated their status"
//
//                descriptionLabel.isHidden = false
//                titleLabel.textColor = creator.color
//
//            case .suggestion:
//                activateBasicLayout()
//                DispatchQueue.main.async {
//                    self.primaryImageBackingView.applyGradient(colors: [.suggestedTop, .suggestedBottom], startPoint: CGPoint(x: 0.5, y: 0), endPoint: CGPoint(x: 0.5, y: 1))
//                }
//                primaryImageView.image = UIImage(named: "PostSuggestionIcon")
//                titleLabel.text = post.people.isEmpty ? "Suggested Camp" : "Suggested Friend"
//
//                descriptionLabel.isHidden = true
//                titleLabel.textColor = .label
//            }

//            if let expiry = post.expiry {
//                timerButton.isHidden = false
//                timerButton.expiryDate = expiry
//                constrain(verticalStackView, timerButton, replace: timerConstraints) {
//                    $0.trailing <= $1.leading - 16
//                }
//            } else {
                timerButton.isHidden = true
                constrain(verticalStackView, replace: timerConstraints) {
                    $0.trailing <= $0.superview!.trailing - 16
                }
//            }
        }
    }

    private var primaryImageBackingView: UIView = .init()
    private var primaryImageView: UIImageView = .init(contentMode: .scaleAspectFill)
    private var verticalStackView: UIStackView = .init(axis: .vertical, spacing: 2)
    private var titleStackView: UIStackView = .init(axis: .horizontal, spacing: 3)
    private var detailStackView: UIStackView = .init(axis: .horizontal, spacing: 4)
    private var titleLabel: UILabel = .init(size: 15, weight: .heavy, multiline: false)
    private var descriptionLabel: UILabel = .init(size: 14, weight: .semibold, color: .secondaryLabel, multiline: false)
    private var secondaryImageView: UIImageView = .init(width: 14, height: 14, cornerRadius: 7, contentMode: .scaleAspectFill)
    private var secondaryLabel: UILabel = .init(size: 14, weight: .bold, color: Constants.Color.primary, multiline: false)

    private var timerButton = TimerButton()

    private var timerConstraints = ConstraintGroup()
    private var imageSizeConstraints = ConstraintGroup()

    init() {
        super.init(frame: .zero)

        setUpPrimaryImageView()
        setUpStackView()
        setUpTimerButton()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpPrimaryImageView() {
        primaryImageBackingView.addSubview(primaryImageView)
        primaryImageBackingView.clipsToBounds = true
        constrain(primaryImageView) { $0.edges == $0.superview!.edges }

        addSubview(primaryImageBackingView)
        constrain(primaryImageBackingView) {
            $0.leading == $0.superview!.leading + 16
            $0.top == $0.superview!.top + 16
            $0.bottom == $0.superview!.bottom - 12
        }

        constrain(primaryImageBackingView, replace: imageSizeConstraints) {
            $0.width == 40
            $0.height == 40
        }
    }

    private func setUpStackView() {
        addSubview(verticalStackView)
        constrain(verticalStackView, primaryImageBackingView) {
            $0.leading == $1.trailing + 8
            $0.centerY == $1.centerY
        }

        constrain(verticalStackView, replace: timerConstraints) {
            $0.trailing == $0.superview!.trailing - 16
        }

        verticalStackView.addArrangedSubview(titleStackView)
        verticalStackView.addArrangedSubview(detailStackView)

        titleStackView.addArrangedSubview(titleLabel)
        titleStackView.addArrangedSubview(descriptionLabel)

        detailStackView.addArrangedSubview(secondaryImageView)
        detailStackView.addArrangedSubview(secondaryLabel)
    }

    private func setUpTimerButton() {
        addSubview(timerButton)
        constrain(timerButton) {
            $0.top == $0.superview!.top + 16
            $0.trailing == $0.superview!.trailing - 16
        }
    }

    private func activatePostLayout() {
        constrain(primaryImageBackingView, replace: imageSizeConstraints) {
            $0.width == 40
            $0.height == 40
        }
        primaryImageBackingView.layer.cornerRadius = 20

        detailStackView.isHidden = false
        layoutIfNeeded()
    }

    private func activateBasicLayout() {
        constrain(primaryImageBackingView, replace: imageSizeConstraints) {
            $0.width == 24
            $0.height == 24
        }
        primaryImageBackingView.layer.cornerRadius = 12

        detailStackView.isHidden = true
        layoutIfNeeded()
    }
}
