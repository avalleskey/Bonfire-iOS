//
//  FeedCellActionView.swift
//  Bonfire
//
//  Created by Daniel Gauthier on 2020-08-21.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import BFCore
import UIKit
import Cartography

protocol FeedCellActionDelegate: AnyObject {
    func performAction()
}

class FeedCellActionView: UIView {

    weak var delegate: FeedCellActionDelegate?

    var type: FeedCellType! {
        didSet {
            switch type {
                case .post(let post):
                    let expired: Bool = post.isExpired
                    let creator = post.attributes.creator ?? User()
                    
                    primaryActionButton.selectable = true
                    primaryActionButton.title = "Like"
                    primaryActionButton.selectedTitle = "Liked!"
                    primaryActionButton.image = UIImage(named: "PostLikeIcon")
                    
                    if let voteCreatedAt = post.attributes.context?.post?.vote?.createdAt {
                        primaryActionButton.setSelected(voteCreatedAt.count > 0)
                    } else {
                        primaryActionButton.setSelected(false)
                    }
                    
                    secondaryActionButton.isHidden = false
                    secondaryActionButton.title = "Message"
                    secondaryActionButton.image = UIImage(named: "PostChatIcon")
                    primaryActionButton.color = expired ? Constants.Color.secondary : creator.attributes.uiColor
                    secondaryActionButton.color = expired ? Constants.Color.secondary : creator.attributes.uiColor
                case .statusUpdate:
                    primaryActionButton.selectable = true
                    primaryActionButton.title = "Like"
                    primaryActionButton.selectedTitle = "Liked!"
                    primaryActionButton.image = UIImage(named: "PostLikeIcon")

                    secondaryActionButton.isHidden = false
                    secondaryActionButton.title = "Message"
                    secondaryActionButton.image = UIImage(named: "PostChatIcon")
                case .suggestion:
//                    if post.people.isEmpty {
//                        primaryActionButton.title = "Join Camp"
//                        primaryActionButton.image = UIImage(named: "PostAddFriendIcon")
//                    } else {
//                        primaryActionButton.title = "Add Friend"
//                        primaryActionButton.image = UIImage(named: "PostAddFriendIcon")
//                    }

                    secondaryActionButton.isHidden = false
                    secondaryActionButton.title = "Ignore"
                    secondaryActionButton.image = UIImage(named: "PostIgnoreIcon")
                default:
                    break
            }
            
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

    private var primaryActionButton = FeedCellActionButton(title: "Test", image: UIImage(named: "PostChatIcon"), color: .liveAudioTop)
    private var secondaryActionButton = FeedCellActionButton(title: "Test", image: UIImage(named: "PostChatIcon"), color: .liveAudioTop)
    private var actionStackView = UIStackView(axis: .horizontal, spacing: 8)

    init() {
        super.init(frame: .zero)
        setUpActionStackView()
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

        primaryActionButton.addTarget(self, action: #selector(primaryActionButtonTapped), for: .touchUpInside)
        secondaryActionButton.addTarget(self, action: #selector(secondaryActionButtonTapped), for: .touchUpInside)
    }

    @objc private func primaryActionButtonTapped() {
        delegate?.performAction()
    }

    @objc private func secondaryActionButtonTapped() {
        delegate?.performAction()
    }
}
