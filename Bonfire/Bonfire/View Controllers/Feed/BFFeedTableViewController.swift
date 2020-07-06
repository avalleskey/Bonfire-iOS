//
//  BFFeedTableViewController.swift
//  Bonfire
//
//  Created by James Dale on 22/6/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation
import UIKit
import BFCore
import Kingfisher

final class BFFeedTableViewController: UITableViewController {
    
    public var posts: [Post] = []
    
    init() {
        super.init(nibName: nil, bundle: nil)
        tableView.register(PostHeaderCell.self,
                           forCellReuseIdentifier: PostHeaderCell.reuseIdentifier)
        tableView.register(PostMessageCell.self,
                           forCellReuseIdentifier: PostMessageCell.reuseIdentifier)
        tableView.register(PostActionsCell.self,
                           forCellReuseIdentifier: PostActionsCell.reuseIdentifier)
        
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        case 0:
            return 58
        case 1:
            return UITableView.automaticDimension
        case 2:
            return 48
        default:
            return 0
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return posts.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let post = posts[section]
        return 3
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        
        let post = posts[indexPath.section]
        
        switch indexPath.row {
        case 0:
            let headerCell = tableView.dequeueReusableCell(withIdentifier: PostHeaderCell.reuseIdentifier,
                                                 for: indexPath) as! PostHeaderCell
            cell = headerCell
            
            headerCell.profileLabel.text = "@" + post.attributes.creator.attributes.identifier
            
            if let camp = post.attributes.postedIn {
                headerCell.campLabel.text = "in " + camp.attributes.title
                headerCell.headerStyle = .camp
            } else {
                headerCell.headerStyle = .profile
            }
            
            if let url = post.attributes.creator.attributes.media?.avatar?.full?.url {
                headerCell.profileImageView.kf.setImage(with: url, options: [.cacheOriginalImage])
            }
        case 1:
            let messageCell = tableView.dequeueReusableCell(withIdentifier: PostMessageCell.reuseIdentifier,
                                                            for: indexPath) as! PostMessageCell
            cell = messageCell
            
            messageCell.messageLabel.text = post.attributes.message
        case 2:
            let actionsCell = tableView.dequeueReusableCell(withIdentifier: PostActionsCell.reuseIdentifier,
                                                            for: indexPath) as! PostActionsCell
            cell = actionsCell
            
            if let replyCount = post.attributes.summaries?.counts?.replies {
                switch replyCount {
                case 0:
                    actionsCell.repliesBtn.setImage(UIImage(named: "ReplyThreshold0"),
                                                    for: .normal)
                case 1..<5:
                    actionsCell.repliesBtn.setImage(UIImage(named: "ReplyThreshold1"),
                                                    for: .normal)
                case 5...24:
                    actionsCell.repliesBtn.setImage(UIImage(named: "ReplyThreshold2"),
                                                    for: .normal)
                default:
                    actionsCell.repliesBtn.setImage(UIImage(named: "ReplyThreshold3"),
                                                    for: .normal)
                }
                actionsCell.repliesBtn.setTitle("\(replyCount) notes", for: .normal)
            } else {
                actionsCell.repliesBtn.setImage(UIImage(named: "ReplyThreshold0"),
                                                for: .normal)
            }
        default:
            fatalError("Unknown row requested in BFFeedView")
        }
        
        return cell
    }
    
}
