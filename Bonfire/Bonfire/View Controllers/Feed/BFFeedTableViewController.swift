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

final class BFFeedTableViewController: UITableViewController {
    
    public var posts: [Post] = [.init(title: "A"),.init(title: "A"),.init(title: "A")]
    
    init() {
        super.init(nibName: nil, bundle: nil)
        tableView.register(PostHeaderCell.self,
                           forCellReuseIdentifier: PostHeaderCell.reuseIdentifier)
        tableView.register(PostActionsCell.self,
                           forCellReuseIdentifier: PostActionsCell.reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return posts.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let post = posts[section]
        return 2
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        
        switch indexPath.row {
        case 0:
            cell = tableView.dequeueReusableCell(withIdentifier: PostHeaderCell.reuseIdentifier,
                                                 for: indexPath)
            cell.backgroundColor = .green
        case 1:
            fallthrough
        default:
            cell = tableView.dequeueReusableCell(withIdentifier: PostActionsCell.reuseIdentifier,
                                                 for: indexPath)
            cell.backgroundColor = .red
        }
        
        return cell
    }
    
}
