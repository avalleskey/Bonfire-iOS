//
//  CampsTableViewController.swift
//  Bonfire
//
//  Created by James Dale on 22/6/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation
import UIKit

final class CampsTableViewController: UITableViewController {
    
    init() {
        super.init(nibName: nil, bundle: nil)
        tableView.register(CampTableViewCell.self,
                           forCellReuseIdentifier: CampTableViewCell.reuseIdentifier)
        tableView.separatorStyle = .none
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 9
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CampTableViewCell.reuseIdentifier,
                                                 for: indexPath)
        
        return cell
    }
}
