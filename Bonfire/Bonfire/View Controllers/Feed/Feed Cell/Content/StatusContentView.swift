//
//  StatusContentView.swift
//  Bonfire
//
//  Created by Daniel Gauthier on 2020-08-21.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit
import Cartography

class StatusContentView: UIView {

    private var status: DummyPost.User.Status

    private let containerView = UIView(backgroundColor: .contentGray, cornerRadius: 30)
    private let emojiLabel = UILabel(size: 32, weight: .bold, multiline: false)
    private let statusLabel = UILabel(size: 24, weight: .bold)
    private let bigBubbleView = UIView(backgroundColor: .contentGray, height: 16, width: 16, cornerRadius: 8)
    private let littleBubbleView = UIView(backgroundColor: .contentGray, height: 6, width: 6, cornerRadius: 3)

    init(status: DummyPost.User.Status) {
        self.status = status
        super.init(frame: .zero)
        setUpContainerView()
        setUpEmojiLabel()
        setUpStatusLabel()
        setUpBubbleViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpContainerView() {
        addSubview(containerView)
        constrain(containerView) {
            $0.top == $0.superview!.top + 4
            $0.leading == $0.superview!.leading + 16
            $0.trailing <= $0.superview!.trailing - 16
            $0.bottom == $0.superview!.bottom
            $0.height >= 60
        }
    }

    private func setUpEmojiLabel() {
        containerView.addSubview(emojiLabel)
        constrain(emojiLabel) {
            $0.leading == $0.superview!.leading + 16
            $0.centerY == $0.superview!.centerY
            if status.text == nil {
                $0.trailing == $0.superview!.trailing - 16
            }
        }

        emojiLabel.text = status.emoji
    }

    private func setUpStatusLabel() {
        containerView.addSubview(statusLabel)
        constrain(statusLabel, emojiLabel) {
            if status.emoji == nil {
                $0.leading == $0.superview!.leading + 16
            } else {
                $0.leading == $1.trailing + 8
            }
            $0.top == $0.superview!.top + 16
            $0.bottom == $0.superview!.bottom - 16
            $0.trailing == $0.superview!.trailing - 16
        }

        statusLabel.text = status.text
    }

    private func setUpBubbleViews() {
        addSubview(bigBubbleView)
        constrain(bigBubbleView, containerView) {
            $0.leading == $1.leading
            $0.top == $1.top
        }

        addSubview(littleBubbleView)
        constrain(littleBubbleView, bigBubbleView) {
            $0.leading == $1.leading
            $0.bottom == $1.top - 3
        }
    }
}
