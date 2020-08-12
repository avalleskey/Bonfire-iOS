//
//  ProfileViewController.swift
//  Bonfire
//
//  Created by James Dale on 29/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit
import BFCore

final class ProfileViewController: UIViewController {

    static var defaultTabBarItem: UITabBarItem {
        UITabBarItem(
            title: "",
            image: Constants.TabBar.meDefaultImage,
            tag: 0)
    }
    
    private let headerView = ProfileHeaderView()
    private let feedTableView = BFFeedTableViewController()
    private let controller = StreamController()
    
    init() {
        super.init(nibName: nil, bundle: nil)
        
        if navigationController?.tabBarController != nil {
            navigationItem.title = Constants.TabBar.meDefaultText
        } else {
            navigationItem.title = "John Smith"
        }
        
        addChild(feedTableView)
        view.addSubview(feedTableView.view)
        feedTableView.tableView.tableHeaderView = headerView
        
        updateViewConstraints()
    }
    
    func __tempUpdatePost(post: Post) {
        feedTableView.posts = [post]
        feedTableView.tableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.delegate = self
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        
        headerView.translatesAutoresizingMaskIntoConstraints = false
        feedTableView.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            feedTableView.view.topAnchor.constraint(equalTo: view.topAnchor),
            feedTableView.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            feedTableView.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            feedTableView.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            headerView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.8),
            headerView.widthAnchor.constraint(equalTo: feedTableView.tableView.widthAnchor)
        ])
    }
    
    private func refresh(user: User) {
        guard let id = user.id else { return }
        controller.getStream(user: id) { (posts) in
            DispatchQueue.main.async {
                self.feedTableView.posts = posts
                self.feedTableView.tableView.reloadData()
            }
        }
    }
    
    
}

// We need this to fix a nasty issue with tab bar controller and navigation controller together
extension ProfileViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }
}
