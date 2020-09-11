//
//  FeedCell.swift
//  Bonfire
//
//  Created by Daniel Gauthier on 2020-08-19.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import BFCore
import UIKit
import Cartography

protocol FeedCellDelegate: AnyObject {
    func performAction()
}

class FeedCell: UITableViewCell {

    weak var delegate: FeedCellDelegate?

    var post: Post! {
        didSet {
            headerView.post = post
            actionView.post = post
            insertContent(PostContentView(post: post))

            // TODO: The commented out code below worked with the DummyPost type.
            // There is work left to be done here to get these other post types (live right now, suggestion, status update)
            // working with real data from the backend, but the UI should all be here and ready to plug into.

//            replyView.replies = post.replies
//
//            switch post.type {
//            case .liveRightNow:
//                insertContent(LiveContentView(camps: post.camps))
//                actionView.isHidden = true
//                replyView.isHidden = true
//            case .post:
//                insertContent(PostContentView(post: post))
//                actionView.isHidden = false
//                replyView.isHidden = false
//            case .statusUpdate:
//                if let status = post.people.first?.status {
//                    insertContent(StatusContentView(status: status))
//                    actionView.isHidden = false
//                }
//                replyView.isHidden = true
//            case .suggestion:
//                if let friend = post.people.first {
//                    insertContent(SuggestionContentView(suggestion: friend))
//                    actionView.isHidden = false
//                } else if let camp = post.camps.first {
//                    insertContent(SuggestionContentView(suggestion: camp))
//                    actionView.isHidden = false
//                }
//                replyView.isHidden = true
//            }
        }
    }

    private var containerView = UIView(backgroundColor: Constants.Color.systemBackground, cornerRadius: 16)
    private var stackView = UIStackView(axis: .vertical)
    private var headerView = FeedCellHeaderView()
    private var contentContainerView = UIView()
    private var actionView = FeedCellActionView()
    private var replyView = FeedCellReplyView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setUpContainerView()
        setUpContentViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        containerView.applyShadow(intensity: .sketch(color: .black, alpha: 0.03, x: 0, y: 1, blur: 3, spread: 0))
        if #available(iOS 13.0, *) { containerView.layer.cornerCurve = .continuous }
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor.black.withAlphaComponent(0.05).cgColor
    }

    private func setUpContainerView() {
        contentView.addSubview(containerView)
        constrain(containerView) {
            $0.top == $0.superview!.top + 6
            $0.leading == $0.superview!.leading + 12
            $0.trailing == $0.superview!.trailing - 12
            $0.bottom == $0.superview!.bottom - 6 ~ .init(rawValue: 999)
        }
    }

    private func setUpContentViews() {
        containerView.addSubview(stackView)
        constrain(stackView) {
            $0.edges == $0.superview!.edges
        }

        stackView.addArrangedSubview(headerView)
        stackView.addArrangedSubview(contentContainerView)
        stackView.addArrangedSubview(actionView)
        stackView.addArrangedSubview(replyView)

        actionView.delegate = self
    }

    private func insertContent(_ view: UIView) {
        contentContainerView.subviews.forEach {
            $0.removeFromSuperview()
        }

        contentContainerView.addSubview(view)
        constrain(view) {
            $0.edges == $0.superview!.edges
        }
    }

    override func prepareForReuse() {
        replyView.prepareForReuse()
    }
}

extension FeedCell: FeedCellActionDelegate {
    func performAction() {
        delegate?.performAction()
    }
}
