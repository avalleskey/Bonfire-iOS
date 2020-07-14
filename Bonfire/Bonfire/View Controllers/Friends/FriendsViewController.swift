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
    
    let addFriendsBtn: UIButton = {
        let btn = UIButton()
        btn.setTitle("Add Friends", for: .normal)
        btn.setTitleColor(.black, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        btn.titleLabel?.font = btn.titleLabel?.font.rounded()
        btn.setImage(UIImage(named: "AddFriends"), for: .normal)
        btn.titleEdgeInsets = .init(top: 0, left: 8, bottom: 0, right: -8)
        btn.contentEdgeInsets = .init(top: 12, left: 16, bottom: 12, right: 16)
        btn.backgroundColor = .white
        btn.layer.shadowColor = UIColor.black.cgColor
        btn.layer.shadowOpacity = 0.12
        btn.layer.shadowOffset = .init(width: 0, height: 2)
        btn.layer.cornerRadius = 20
        btn.layer.shadowRadius = 6
        return btn
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) { view.backgroundColor = .systemBackground }
        
        view.addSubview(friendsTableView.view)
        view.addSubview(addFriendsBtn)
        
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
        
        updateViewConstraints()
    }
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        
        addFriendsBtn.translatesAutoresizingMaskIntoConstraints = false
        friendsTableView.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            friendsTableView.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            friendsTableView.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            friendsTableView.view.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            friendsTableView.view.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
        ])
        
        NSLayoutConstraint.activate([
            addFriendsBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            addFriendsBtn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                                                  constant: -16),
        ])
    }


}

