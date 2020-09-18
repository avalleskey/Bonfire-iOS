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
    func replyButtonTapped()
}

enum FeedCellType {
    case post(post: Post)
    case liveRightNow
    case statusUpdate
    case suggestion
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
                    
                    var archived: Bool = true
                    if let createdAt = post.attributes.createdAt {
                        let expiry: Date = (expiryFormatter.date(from: createdAt)?.addingTimeInterval(60 * 60 * 24))!
                        let secondsLeft = Int(expiry.timeIntervalSince(Date()))
                        archived = secondsLeft < 0
                    }
                    contentContainerView.alpha = archived ? 0.75 : 1
                    replyView.isHidden = archived
                    
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

    private var containerView = UIView(backgroundColor: Constants.Color.systemBackground, cornerRadius: 0)
    private var stackView = UIStackView(axis: .vertical)
    private var headerView = FeedCellHeaderView()
    private var contentContainerView = UIView()
    private var actionView = FeedCellActionView()
    private var replyView = FeedCellReplyView()
    
    private let expiryFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return formatter
    }()
    
    let separatorView = UIView(backgroundColor: Constants.Color.separatorColor.withAlphaComponent(0.5), height: 4)

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
//        containerView.applyShadow(intensity: .sketch(color: .black, alpha: 0.03, x: 0, y: 1, blur: 3, spread: 0))
        if #available(iOS 13.0, *) { containerView.layer.cornerCurve = .continuous }
//        containerView.layer.borderWidth = 1
//        containerView.layer.borderColor = UIColor.black.withAlphaComponent(0.05).cgColor
    }

    private func setUpContainerView() {
        contentView.addSubview(containerView)
        constrain(containerView) {
            $0.top == $0.superview!.top
            $0.leading == $0.superview!.leading
            $0.trailing == $0.superview!.trailing
            $0.bottom == $0.superview!.bottom ~ .init(rawValue: 999)
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
        stackView.addArrangedSubview(separatorView)

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
