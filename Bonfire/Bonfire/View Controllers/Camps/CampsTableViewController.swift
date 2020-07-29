//
//  CampsTableViewController.swift
//  Bonfire
//
//  Created by James Dale on 22/6/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import BFCore
import Foundation
import Kingfisher
import UIKit

final class CampsTableViewController: UITableViewController {

    var camps: [Camp] = []

    init() {
        super.init(nibName: nil, bundle: nil)
        tableView.register(
            CampTableViewCell.self,
            forCellReuseIdentifier: CampTableViewCell.reuseIdentifier)
        tableView.separatorStyle = .none
        tableView.contentInset.bottom = 16 + 42 + 16
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return camps.count
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
                withIdentifier: CampTableViewCell.reuseIdentifier,
                for: indexPath) as! CampTableViewCell

        let camp = camps[indexPath.row]
        cell.updateWithCamp(camp: camp)
        
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let detailView = CampDetailViewController()
        detailView.hero.isEnabled = true
        detailView.heroModalAnimationType = .push(direction: .leading)
        detailView.modalPresentationStyle = .fullScreen

        present(detailView, animated: true)
    }
}
