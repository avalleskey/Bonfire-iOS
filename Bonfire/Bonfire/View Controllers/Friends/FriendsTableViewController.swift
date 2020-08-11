//
//  FriendsTableViewController.swift
//  Bonfire
//
//  Created by James Dale on 21/6/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import BFCore
import UIKit

final class FriendsTableViewController: UITableViewController {

    var friends: [User] = []
    
    var pinned: [User] = [] {
        didSet {
            pinCollectionView.pins = pinned.map { Pin($0)}
        }
    }
    
    private let pinCollectionView = PinCollectionViewController()

    init() {
        super.init(nibName: nil, bundle: nil)
        tableView.register(
            FriendTableViewCell.self,
            forCellReuseIdentifier: FriendTableViewCell.reuseIdentifier)
        tableView.separatorStyle = .none
        tableView.tableHeaderView = pinCollectionView.view
        updateViewConstraints()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return friends.count
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath)
        -> CGFloat
    {
        return 72
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath)
        -> UITableViewCell
    {
        let cell =
            tableView.dequeueReusableCell(
                withIdentifier: FriendTableViewCell.reuseIdentifier,
                for: indexPath) as! FriendTableViewCell

        let friend = friends[indexPath.row]
        cell.updateWithUser(user: friend)

        return cell
    }
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        
        NSLayoutConstraint.activate([
            pinCollectionView.view.leadingAnchor.constraint(equalTo: tableView.leadingAnchor),
            pinCollectionView.view.trailingAnchor.constraint(equalTo: tableView.trailingAnchor),
            
        ])
    }
}
