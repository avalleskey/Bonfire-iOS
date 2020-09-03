//
//  FeedCellReplyView.swift
//  Bonfire
//
//  Created by Daniel Gauthier on 2020-08-26.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit
import Cartography

class FeedCellReplyView: UIView {

    var replies: [DummyPost.Reply] = [] {
        didSet {
            for reply in replies {
                stackView.insertArrangedSubview(ReplyCell(reply: reply), at: 0)
            }
        }
    }

    private let stackView = UIStackView(axis: .vertical)
    private let createReplyView = UIView()
    private let avatarImageView = UIImageView(width: 32, height: 32, cornerRadius: 16, contentMode: .scaleAspectFill)
    private let addReplyLabel = UILabel(size: 16, weight: .medium, color: .tertiaryLabel, multiline: false, text: "Add a reply...")

    init() {
        super.init(frame: .zero)
        setUpStackView()
        setUpCreateReplyView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpStackView() {
        addSubview(stackView)
        constrain(stackView) {
            $0.top == $0.superview!.top
            $0.leading == $0.superview!.leading
            $0.trailing == $0.superview!.trailing
            $0.bottom == $0.superview!.bottom - 8
        }
    }

    private func setUpCreateReplyView() {
        createReplyView.addSubview(avatarImageView)
        constrain(avatarImageView) {
            $0.leading == $0.superview!.leading + 16
            $0.top == $0.superview!.top + 8
            $0.bottom == $0.superview!.bottom - 8
        }

        avatarImageView.image = UIImage(named: "Pinwheel")!

        createReplyView.addSubview(addReplyLabel)
        constrain(addReplyLabel, avatarImageView) {
            $0.leading == $1.trailing + 8
            $0.centerY == $1.centerY
            $0.trailing == $0.superview!.trailing - 16
        }

        stackView.addArrangedSubview(createReplyView)
    }

    func prepareForReuse() {
        stackView.arrangedSubviews.forEach {
            guard $0 != createReplyView else { return }
            $0.removeFromSuperview()
        }
    }
}
