//
//  FeedCellActionView.swift
//  Bonfire
//
//  Created by Daniel Gauthier on 2020-08-21.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit
import Cartography

class FeedCellActionView: UIView {
    var post: DummyPost! {
        didSet {
            switch post.type {
            case .liveRightNow:
                primaryActionButton.title = "Like"
                primaryActionButton.image = UIImage(named: "PostLikeIcon")

                secondaryActionButton.isHidden = false
                secondaryActionButton.title = "Reply"
                secondaryActionButton.image = UIImage(named: "PostReplyIcon")
            case .post:
                primaryActionButton.title = "Like"
                primaryActionButton.image = UIImage(named: "PostLikeIcon")

                secondaryActionButton.isHidden = false
                secondaryActionButton.title = "Message"
                secondaryActionButton.image = UIImage(named: "PostChatIcon")
            case .statusUpdate:
                primaryActionButton.title = "Message"
                primaryActionButton.image = UIImage(named: "PostChatIcon")

                secondaryActionButton.isHidden = true
            case .suggestedFriend:
                primaryActionButton.title = "Add Friend"
                primaryActionButton.image = UIImage(named: "PostAddFriendIcon")

                secondaryActionButton.isHidden = false
                secondaryActionButton.title = "Ignore"
                secondaryActionButton.image = UIImage(named: "PostIgnoreIcon")
            }
        }
    }

    private var primaryActionButton = ActionButton(title: "Test", image: UIImage(named: "PostChatIcon"), color: .systemPink)
    private var secondaryActionButton = ActionButton(title: "Test", image: UIImage(named: "PostChatIcon"), color: .systemPink)
    private var actionStackView = UIStackView(axis: .horizontal, spacing: 8)
    private var detailsButton = UIButton(image: UIImage(named: "PostMoreIcon"), contentColor: .systemPink, width: 36, height: 36)

    init() {
        super.init(frame: .zero)
        setUpActionStackView()
        setUpDetailsButton()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpActionStackView() {
        addSubview(actionStackView)
        constrain(actionStackView) {
            $0.top == $0.superview!.top + 10
            $0.leading == $0.superview!.leading + 16
            $0.bottom == $0.superview!.bottom - 16
        }

        actionStackView.addArrangedSubview(primaryActionButton)
        actionStackView.addArrangedSubview(secondaryActionButton)
    }

    private func setUpDetailsButton() {
        addSubview(detailsButton)
        constrain(detailsButton) {
            $0.trailing == $0.superview!.trailing - 14
            $0.bottom == $0.superview!.bottom - 16
        }
    }
}
