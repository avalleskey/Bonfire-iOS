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

protocol FeedCellHeaderViewDelegate: AnyObject {
    func moreButtonTapped()
    func openUser(user: User)
    func openCamp(camp: Camp)
}

class FeedCellHeaderView: UIView {
    
    weak var delegate: FeedCellHeaderViewDelegate?
    
    var post: Post! {
        didSet {
            let creator = post.attributes.creator ?? User()
            let camp = post.attributes.postedIn ?? Camp()
            let expired: Bool = post.isExpired
            
            activatePostLayout()
            primaryImageView.kf.setImage(with: creator.attributes.media?.avatar?.full?.url)
            titleLabel.text = String(htmlEncodedString: creator.attributes.displayName)
            secondaryImageView.kf.setImage(with: camp.attributes.media?.avatar?.full?.url)
            secondaryLabel.text = camp.attributes.title
            descriptionLabel.isHidden = true
            titleLabel.textColor = expired ? Constants.Color.secondary : creator.attributes.uiColor
            secondaryLabel.textColor = expired ? Constants.Color.secondary : Constants.Color.primary
            moreButton.tintColor = expired ? Constants.Color.secondary : creator.attributes.uiColor

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

            if let createdAt = post.attributes.createdAt {
                timerButton.isHidden = false
                timerButton.expiryDate = expiryFormatter.date(from: createdAt)?.addingTimeInterval(60 * 60 * 24)
                constrain(verticalStackView, timerButton, replace: timerConstraints) {
                    $0.trailing <= $1.leading - 16
                }
            } else {
                timerButton.isHidden = true
                constrain(verticalStackView, replace: timerConstraints) {
                    $0.trailing <= $0.superview!.trailing - 16
                }
            }
        }
    }

    private var primaryImageBackingView: UIView = .init()
    private var primaryImageView: UIImageView = .init(contentMode: .scaleAspectFill)
    private var verticalStackView: UIStackView = .init(axis: .vertical, spacing: 2)
    private var titleStackView: UIStackView = .init(axis: .horizontal, spacing: 3)
    private var detailStackView: UIStackView = .init(axis: .horizontal, spacing: 4)
    private var titleLabel: UILabel = .init(size: 15, weight: .heavy, multiline: false)
    private var descriptionLabel: UILabel = .init(size: 14, weight: .semibold, color: .secondaryText, multiline: false)
    private var secondaryImageView: UIImageView = .init(width: 16, height: 16, cornerRadius: 8, contentMode: .scaleAspectFill)
    private var secondaryLabel: UILabel = .init(size: 14, weight: .bold, color: Constants.Color.primary, multiline: false)

    private var timerButton = TimerButton()
    private var moreButton = UIButton(image: UIImage(named: "PostMoreIcon"), padding: 16, systemButton: true)

    private var timerConstraints = ConstraintGroup()
    private var imageSizeConstraints = ConstraintGroup()
    
    private let expiryFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return formatter
    }()

    init() {
        super.init(frame: .zero)

        setUpPrimaryImageView()
        setUpStackView()
        setUpButtons()
        setUpTapRecognizers()
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

        constrain(primaryImageBackingView) {
            $0.width == 42
            $0.height == 42
        }
        primaryImageBackingView.layer.cornerRadius = 21
    }

    private func setUpStackView() {
        addSubview(verticalStackView)
        constrain(verticalStackView, primaryImageBackingView) {
            $0.leading == $1.trailing + 10
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

    private func setUpButtons() {
        addSubview(timerButton)
        addSubview(moreButton)
        
        constrain(timerButton, moreButton) { timerButton, moreButton in
            moreButton.trailing == moreButton.superview!.trailing
            moreButton.centerY == moreButton.superview!.centerY
            
            timerButton.trailing == moreButton.leading
            timerButton.centerY == timerButton.superview!.centerY
        }
        
        moreButton.addTarget(self, action: #selector(moreButtonTapped), for: .touchUpInside)
    }
    
    private func setUpTapRecognizers() {
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(openCreator))
        primaryImageBackingView.addGestureRecognizer(tapRecognizer)
        
        let tapToOpenProfile: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(openCreator))
        titleStackView.addGestureRecognizer(tapToOpenProfile)
        
        let tapToOpenCamp: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(openCamp))
        detailStackView.addGestureRecognizer(tapToOpenCamp)
    }
    
    @objc private func moreButtonTapped() {
        delegate?.moreButtonTapped()
    }
    @objc private func openCreator() {
        if let creator = post.attributes.creator {
            delegate?.openUser(user: creator)
        }
    }
    @objc private func openCamp() {
        guard let camp = post.attributes.postedIn else { return }
        delegate?.openCamp(camp: camp)
    }

    private func activatePostLayout() {
        detailStackView.isHidden = false
        layoutIfNeeded()
    }

    private func activateBasicLayout() {
        detailStackView.isHidden = true
        layoutIfNeeded()
    }
}
