//
//  FeedCellReplyView.swift
//  Bonfire
//
//  Created by Daniel Gauthier on 2020-08-26.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit
import Cartography

protocol FeedCellReplyViewDelegate: AnyObject {
    func replyButtonTapped()
}

class FeedCellReplyView: UIView {

    weak var delegate: FeedCellReplyViewDelegate?
    
    var replies: [DummyPost.Reply] = [] {
        didSet {
            for reply in replies {
                stackView.insertArrangedSubview(ReplyCell(reply: reply), at: 0)
            }
        }
    }

    private let stackView = UIStackView(axis: .vertical)
    private let createReplyView = UIView()
    private let avatarImageView = UIImageView(width: 42, height: 42, cornerRadius: 21, contentMode: .scaleAspectFill)
    private let addReplyButton: UIButton = {
        let button = UIButton(title: "Add a reply...", textFormat: (size: 16, weight: .semibold), height: 42, cornerRadius: 21)
        button.backgroundColor = Constants.Color.textFieldBackground
        button.setTitleColor(Constants.Color.secondary, for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        button.contentHorizontalAlignment = .leading
        button.addTarget(self, action: #selector(addReplyButtonTapped), for: .touchUpInside)
        return button
    }()
    @objc private func addReplyButtonTapped() {
        delegate?.replyButtonTapped()
    }

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
            $0.bottom == $0.superview!.bottom
        }
    }

    private func setUpCreateReplyView() {
        createReplyView.addSubview(avatarImageView)

        avatarImageView.image = UIImage(named: "Pinwheel")!
        constrain(avatarImageView) {
            $0.leading == $0.superview!.leading + 16
        }

        createReplyView.addSubview(addReplyButton)
        constrain(addReplyButton, avatarImageView) {
            $0.top == $0.superview!.top + 4
            $0.bottom == $0.superview!.bottom - 16
            $0.leading == $1.trailing + 10
            $0.trailing == $0.superview!.trailing - 16
            
            $1.centerY == $0.centerY
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
