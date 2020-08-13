//
//  BFFeedTableViewController.swift
//  Bonfire
//
//  Created by James Dale on 22/6/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import BFCore
import Foundation
import Kingfisher
import UIKit

protocol BFFeedTableViewControllerDelegate: class {

}

final class BFFeedTableViewController: UITableViewController {

    public var posts: [Post] = []

    public var enableConversationView: Bool = false {
        didSet {
            tableView.allowsSelection = enableConversationView
        }
    }

    public var showsReplyCell = true { didSet { tableView.reloadData() } }

    private var transitionDelegate: BFModalTransitioningDelegate?

    init() {
        super.init(nibName: nil, bundle: nil)
        tableView.register(
            PostHeaderCell.self,
            forCellReuseIdentifier: PostHeaderCell.reuseIdentifier)
        tableView.register(
            PostMessageCell.self,
            forCellReuseIdentifier: PostMessageCell.reuseIdentifier)
        tableView.register(
            PostActionsCell.self,
            forCellReuseIdentifier: PostActionsCell.reuseIdentifier)
        tableView.register(
            AddReplyCell.self,
            forCellReuseIdentifier: AddReplyCell.reuseIdentifier)
        tableView.register(
            PostImageAttachmentCell.self,
            forCellReuseIdentifier: PostImageAttachmentCell.reuseIdentifier)

        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .onDrag
        tableView.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath)
        -> CGFloat
    {
        let post = posts[indexPath.section]
        let type = postCellTypes(for: post)[indexPath.row]
        return type.rowHeight
    }

    func postCellTypes(for post: Post) -> [BFPostCell.Type] {
        var types: [BFPostCell.Type] = [PostHeaderCell.self, PostMessageCell.self]

        post.attributes
            .attachments?
            .media?
            .forEach { _ in types.append(PostImageAttachmentCell.self) }

        if showsReplyCell {
            types.append(AddReplyCell.self)
        }

        types.append(PostActionsCell.self)
        return types
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return posts.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let post = posts[section]
        return postCellTypes(for: post).count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath)
        -> UITableViewCell
    {
        let cell: UITableViewCell

        let post = posts[indexPath.section]
        let type = postCellTypes(for: post)[indexPath.row]

        switch type {
        case is PostHeaderCell.Type:
            let headerCell =
                tableView.dequeueReusableCell(
                    withIdentifier: PostHeaderCell.reuseIdentifier,
                    for: indexPath) as! PostHeaderCell
            cell = headerCell
            headerCell.delegate = self
            headerCell.profileImageView.addTarget(
                headerCell, action: #selector(PostHeaderCell.profileImageTap(sender:)),
                for: .touchUpInside)
            headerCell.profileLabel.text = String(
                htmlEncodedString: post.attributes.creator.attributes.display_name)
            //            headerCell.profileLabel.textColor = UIColor.init(hex: post.attributes.creator.attributes.color)

            if let camp = post.attributes.postedIn {
                headerCell.campLabel.text = String(htmlEncodedString: "in " + camp.attributes.title)
                headerCell.headerStyle = .camp
            } else {
                headerCell.headerStyle = .profile
            }

            if let url = post.attributes.creator.attributes.media?.avatar?.full?.url {
                headerCell.profileImageView.kf.setImage(
                    with: url, for: .normal, options: [.cacheOriginalImage])
            }
        case is PostMessageCell.Type:
            let messageCell =
                tableView.dequeueReusableCell(
                    withIdentifier: PostMessageCell.reuseIdentifier,
                    for: indexPath) as! PostMessageCell
            cell = messageCell
            messageCell.messageLabel.text = String(htmlEncodedString: post.attributes.message ?? "")
        case is PostActionsCell.Type:
            let actionsCell =
                tableView.dequeueReusableCell(
                    withIdentifier: PostActionsCell.reuseIdentifier,
                    for: indexPath) as! PostActionsCell
            cell = actionsCell

            if let replyCount = post.attributes.summaries?.counts?.replies {
                switch replyCount {
                case 0:
                    actionsCell.repliesBtn.setImage(
                        UIImage(named: "ReplyThreshold0"),
                        for: .normal)
                case 1..<5:
                    actionsCell.repliesBtn.setImage(
                        UIImage(named: "ReplyThreshold1"),
                        for: .normal)
                case 5...24:
                    actionsCell.repliesBtn.setImage(
                        UIImage(named: "ReplyThreshold2"),
                        for: .normal)
                default:
                    actionsCell.repliesBtn.setImage(
                        UIImage(named: "ReplyThreshold3"),
                        for: .normal)
                }
                actionsCell.repliesBtn.setTitle("\(replyCount) notes", for: .normal)
            } else {
                actionsCell.repliesBtn.setImage(
                    UIImage(named: "ReplyThreshold0"),
                    for: .normal)
            }
        case is AddReplyCell.Type:
            let replyCell =
                tableView.dequeueReusableCell(
                    withIdentifier: AddReplyCell.reuseIdentifier,
                    for: indexPath) as! AddReplyCell
            cell = replyCell
        case is PostImageAttachmentCell.Type:
            let imageCell =
                tableView.dequeueReusableCell(
                    withIdentifier: type.reuseIdentifier,
                    for: indexPath) as! PostImageAttachmentCell
            cell = imageCell
            if let url = post.attributes.attachments?.media?.first?.attributes.hostedVersions.full?
                .url
            {
                imageCell.attachmentImageView.kf.setImage(with: url, options: [.cacheOriginalImage])
            }
        default:
            cell = tableView.dequeueReusableCell(
                withIdentifier: type.reuseIdentifier,
                for: indexPath)
        }

        cell.selectionStyle = .none
        return cell
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int)
        -> UIView?
    {
        return UIView()
    }
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int)
        -> CGFloat
    {
        return section == 0 ? 24 : 16
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int)
        -> UIView?
    {
        return nil
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int)
        -> CGFloat
    {
        return 0
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = posts[indexPath.section]
        let conversationVC = ConversationViewController(post: post)
        let navVC = BFModalNavigationController(root: conversationVC)
        navVC.modalPresentationStyle = .custom
        transitionDelegate = BFModalTransitioningDelegate(from: self, to: navVC)
        navVC.transitioningDelegate = transitionDelegate
        present(navVC, animated: true)
    }

}

extension BFFeedTableViewController: PostHeaderCellDelegate {
    func profileBtnTap(cell: UITableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let post = posts[indexPath.section]

        let profileView = ProfileViewController()
        profileView.update(user: post.attributes.creator)
        profileView.load(id: post.attributes.creator.id!)
        profileView.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(profileView, animated: true)
    }
}
