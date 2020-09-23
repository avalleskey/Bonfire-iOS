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
    func moreButtonTapped()
    func performAction()
    func openUser(user: User)
    func openCamp(camp: Camp)
    func replyButtonTapped()
}

enum FeedCellType {
    case post(post: Post)
    case liveRightNow
    case statusUpdate
    case suggestion
}

enum FeedCellStyle {
    case normal
    case rounded
}

class FeedCell: UITableViewCell {

    weak var delegate: FeedCellDelegate?
    
    var type: FeedCellType! {
        didSet {
            actionView.type = type
            
            switch type {
                case .post(let post):
                    headerView.isHidden = false
                    replyView.isHidden = false
                    headerView.post = post
                    actionView.isHidden = false
                    
                    let expired: Bool = post.isExpired
                    contentContainerView.alpha = expired ? 0.8 : 1
                    replyView.isHidden = expired
                    
                    insertContent(PostContentView(post: post))
                case .liveRightNow:
                    headerView.isHidden = true
                    replyView.isHidden = true
                    actionView.isHidden = true
                    
                    insertContent(LiveContentView(camps: []))
                case .statusUpdate:
                    headerView.isHidden = true
                    replyView.isHidden = true
                    actionView.isHidden = false
                    
                    insertContent(LiveContentView(camps: []))
                case .suggestion:
                    headerView.isHidden = true
                    replyView.isHidden = true
                    actionView.isHidden = false
                    
                    insertContent(LiveContentView(camps: []))
                case .none:
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
    
    var style: FeedCellStyle! {
        didSet {
            switch style {
                case .normal:
                    containerView.layer.cornerRadius = 0
                    containerView.layer.shadowOpacity = 0
                    containerViewWidthConstraint?.constant = 0
                    containerViewSeparatorConstraint?.constant = -2
                case .rounded:
                    containerViewWidthConstraint?.constant = -24
                    containerView.layer.cornerRadius = 10
                    if #available(iOS 13.0, *) {
                        containerView.layer.cornerCurve = .continuous
                    }
                    containerView.applyShadow(intensity: .sketch(color: .black, alpha: 0.08, x: 0, y: 1, blur: 3, spread: 0))
                    containerViewSeparatorConstraint?.constant = -12
                case .none:
                    break
            }
            containerView.layoutIfNeeded()
        }
    }

    private var containerView = UIView(backgroundColor: Constants.Color.postBackground, cornerRadius: 0)
    private var stackView = UIStackView(axis: .vertical)
    private var headerView = FeedCellHeaderView()
    private var contentContainerView = UIView()
    private var actionView = FeedCellActionView()
    private var replyView = FeedCellReplyView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        backgroundColor = Constants.Color.groupedBackground
        contentView.backgroundColor = backgroundColor
        setUpContainerView()
        setUpContentViews()
        
        defer {
            self.style = .normal
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }

    var containerViewWidthConstraint: NSLayoutConstraint?
    var containerViewSeparatorConstraint: NSLayoutConstraint?
    private func setUpContainerView() {
        contentView.addSubview(containerView)
        constrain(containerView) {
            $0.top == $0.superview!.top
            $0.centerX == $0.superview!.centerX
            containerViewSeparatorConstraint = ($0.bottom == $0.superview!.bottom ~ .init(rawValue: 999))
            containerViewWidthConstraint = ($0.width == $0.superview!.width)
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

        headerView.delegate = self
        actionView.delegate = self
        replyView.delegate = self
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

extension FeedCell: FeedCellHeaderViewDelegate {
    func openUser(user: User) {
        delegate?.openUser(user: user)
    }
    func openCamp(camp: Camp) {
        delegate?.openCamp(camp: camp)
    }
    func moreButtonTapped() {
        delegate?.moreButtonTapped()
    }
}
extension FeedCell: FeedCellActionDelegate {
    func performAction() {
        delegate?.performAction()
    }
}
extension FeedCell: FeedCellReplyViewDelegate {
    func replyButtonTapped() {
        delegate?.replyButtonTapped()
    }
}
