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
    
    let addFriendsBtn: UIButton = {
        let btn = UIButton()
        btn.setTitle("Add Friends", for: .normal)
        btn.setTitleColor(.black, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        btn.titleLabel?.font = btn.titleLabel?.font.rounded()
        btn.backgroundColor = .white
        return btn
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) { view.backgroundColor = .systemBackground }
        
        view.addSubview(friendsTableView.view)
        view.addSubview(addFriendsBtn)
        
        updateViewConstraints()
    }
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        
        addFriendsBtn.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            addFriendsBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            addFriendsBtn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                                                  constant: -16),
        ])
    }


}

