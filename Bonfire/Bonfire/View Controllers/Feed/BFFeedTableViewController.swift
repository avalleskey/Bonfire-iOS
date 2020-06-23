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
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return posts.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let post = posts[section]
        return 3
    }
    
}
