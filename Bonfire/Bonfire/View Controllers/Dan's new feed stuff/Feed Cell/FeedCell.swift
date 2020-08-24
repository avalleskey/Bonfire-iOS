//
//  FeedCell.swift
//  Bonfire
//
//  Created by Daniel Gauthier on 2020-08-19.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit
import Cartography

class FeedCell: UITableViewCell {

    var post: DummyPost! {
        didSet {
            headerView.post = post
            actionView.post = post

            switch post.type {
            case .liveRightNow:
                insertContent(LiveContentView(camps: post.camps))
                actionView.isHidden = true
            case .post:
                insertContent(PostContentView())
                actionView.isHidden = false
            case .statusUpdate:
                insertContent(StatusContentView())
                actionView.isHidden = false
            case .suggestedFriend:
                if let friend = post.people.first {
                    insertContent(SuggestionContentView(suggestion: friend))
                    actionView.isHidden = false
                }

            }
        }
    }

    private var containerView = UIView(backgroundColor: Constants.Color.systemBackground, cornerRadius: 24, shadowIntensity: .diffuse)
    private var stackView = UIStackView(axis: .vertical)
    private var headerView = FeedCellHeaderView()
    private var contentContainerView = UIView()
    private var actionView = FeedCellActionView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setUpContainerView()
        setUpContentViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpContainerView() {
        contentView.addSubview(containerView)
        constrain(containerView) {
            $0.top == $0.superview!.top + 12
            $0.leading == $0.superview!.leading + 16
            $0.trailing == $0.superview!.trailing - 16
            $0.bottom == $0.superview!.bottom - 12
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
}
