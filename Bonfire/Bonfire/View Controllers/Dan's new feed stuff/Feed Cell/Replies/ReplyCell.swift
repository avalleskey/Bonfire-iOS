//
//  ReplyCell.swift
//  Bonfire
//
//  Created by Daniel Gauthier on 2020-08-26.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit
import Cartography

class ReplyCell: UIView {

    var reply: DummyPost.Reply

    private let avatarImageView = UIImageView(width: 24, height: 24, cornerRadius: 12, contentMode: .scaleAspectFill)
    private let nameLabel = UILabel(size: 16, weight: .bold, color: .secondaryLabel, multiline: false)
    private let messageLabel = UILabel(size: 16, weight: .medium, multiline: true)
    private let likeButton = UIButton(image: UIImage(named: "ReplyLikeIcon"), contentColor: .secondaryLabel, width: 36, height: 36, systemButton: true)

    init(reply: DummyPost.Reply) {
        self.reply = reply
        super.init(frame: .zero)

        setUpAvatarImageView()
        setUpLikeButton()
        setUpNameLabel()
        setUpMessageLabel()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpAvatarImageView() {
        addSubview(avatarImageView)
        constrain(avatarImageView) {
            $0.leading == $0.superview!.leading + 16
            $0.top == $0.superview!.top + 8
        }

        avatarImageView.image = reply.user.image
    }

    private func setUpLikeButton() {
        addSubview(likeButton)
        constrain(likeButton) {
            $0.top == $0.superview!.top
            $0.trailing == $0.superview!.trailing - 6
        }
    }

    private func setUpNameLabel() {
        addSubview(nameLabel)
        constrain(nameLabel, avatarImageView, likeButton) {
            $0.top == $0.superview!.top + 8
            $0.leading == $1.trailing + 8
            $0.trailing == $2.leading - 8
        }

        nameLabel.text = reply.user.name
    }

    private func setUpMessageLabel() {
        addSubview(messageLabel)
        constrain(messageLabel, nameLabel, likeButton) {
            $0.top == $1.bottom
            $0.leading == $1.leading
            $0.bottom == $0.superview!.bottom - 8
            $0.trailing == $2.leading - 8
        }

        messageLabel.text = reply.message
    }
}
