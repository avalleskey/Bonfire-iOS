//
//  FriendsViewController.swift
//  Bonfire
//
//  Created by James Dale on 20/6/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation
import UIKit

final class FriendsViewController: UIViewController {

    static var defaultTabBarItem: UITabBarItem {
        UITabBarItem(
            title: Constants.TabBar.friendsDefaultText,
            image: Constants.TabBar.friendsDefaultImage,
            tag: 0)
    }

    private let activityIndicator: UIActivityIndicatorView = {
        var indicator = UIActivityIndicatorView(style: .whiteLarge)
        indicator.color = Constants.Color.secondary
        return indicator
    }()
    private let friendsTableView = FriendsTableViewController()
    private let controller = UserController()

    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) { view.backgroundColor = .systemBackground }

        view.addSubview(friendsTableView.view)
        view.addSubview(activityIndicator)

        refresh()

        updateViewConstraints()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        refresh()
    }

    private func refresh() {
        activityIndicator.startAnimating()
        controller.getFriends { (result) in
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                switch result {
                case .success(let friends):
                    self.friendsTableView.friends = friends
                    self.friendsTableView.tableView.reloadData()
                case .failure(let error):
                    switch BFAppError.from(error: error) {
                    case .unauthenticated:
                        let authController = GetStartedViewController()
                        let authNavcontroller = GetStartedNavigationController(rootViewController: authController)
                        self.present(authNavcontroller, animated: true)
                    default:
                        print(error)
                    }
                    
                }
            }
        }
    }

    override func updateViewConstraints() {
        super.updateViewConstraints()

        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        friendsTableView.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            friendsTableView.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            friendsTableView.view.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            friendsTableView.view.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            friendsTableView.view.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor),
        ])
    }

}
