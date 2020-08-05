//
//  PostViewController.swift
//  Bonfire
//
//  Created by James Dale on 4/8/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit
import BFCore

final class ConversationViewController: UIKeyboardSubscribedViewController {
    
    private let post: Post
    
    private let homeFeedTableView = BFFeedTableViewController()
    
    init(post: Post) {
        self.post = post
        super.init(nibName: nil, bundle: nil)
        
        homeFeedTableView.showsReplyCell = false
        homeFeedTableView.posts = [post]
        
        addChild(homeFeedTableView)
        view.addSubview(homeFeedTableView.view)
        
        navigationItem.title = "Conversation"
        
        updateViewConstraints()
        subscribeToKeyboard()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        
        homeFeedTableView.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            homeFeedTableView.view.topAnchor.constraint(equalTo: view.topAnchor),
            homeFeedTableView.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            homeFeedTableView.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            homeFeedTableView.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }
    
}
