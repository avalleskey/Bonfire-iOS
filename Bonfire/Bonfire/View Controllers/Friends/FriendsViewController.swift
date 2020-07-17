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
        UITabBarItem(title: Constants.TabBar.friendsDefaultText,
                     image: Constants.TabBar.friendsDefaultImage,
                     tag: 0)
    }
    
    let friendsTableView = FriendsTableViewController()
    let controller = UserController()

    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) { view.backgroundColor = .systemBackground }
        
        view.addSubview(friendsTableView.view)
        
        refresh()
        
        updateViewConstraints()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        refresh()
    }
    
    func refresh() {
        controller.getFriends { (result) in
            switch result {
            case .success(let friends):
                DispatchQueue.main.async {
                    self.friendsTableView.friends = friends
                    self.friendsTableView.tableView.reloadData()
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    switch BFAppError.from(error: error) {
                    case .unauthenticated:
                        let authController = GetStartedViewController()
                        self.present(authController, animated: true)
                    default:
                        print(error)
                    }
                }
            }
            
        }
    }
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        
        friendsTableView.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            friendsTableView.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            friendsTableView.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            friendsTableView.view.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            friendsTableView.view.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
        ])
    }


}
