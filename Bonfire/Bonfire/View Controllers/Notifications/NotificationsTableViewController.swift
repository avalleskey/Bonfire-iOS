//
//  NotificationsTableViewController.swift
//  Bonfire
//
//  Created by Austin Valleskey on 24/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import BFCore
import UIKit

final class NotificationsTableViewController: UITableViewController {

    var notifications: [UserActivity] = []

    init() {
        super.init(nibName: nil, bundle: nil)
        tableView.register(
            NotificationTableViewCell.self,
            forCellReuseIdentifier: NotificationTableViewCell.reuseIdentifier)
        tableView.separatorStyle = .none
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notifications.count
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath)
        -> CGFloat
    {
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath)
        -> UITableViewCell
    {
        let cell =
            tableView.dequeueReusableCell(
                withIdentifier: NotificationTableViewCell.reuseIdentifier,
                for: indexPath) as! NotificationTableViewCell

        let notification = notifications[indexPath.row]
        cell.type = UserActivityType(rawValue: notification.attributes.type) ?? .unknown
        cell.read = notification.attributes.read

        if let title = notification.attributes.title {
            cell.titleLabel.attributedText = .entityString(
                string: title.title, entities: title.entities)
        }

        cell.dateLabel.text = notification.attributes.createdAt.timeAgoDisplay()

        if let actioner = notification.attributes.actioner,
            let url = actioner.attributes.media?.avatar?.full?.url
        {
            cell.profileImageView.kf.setImage(with: url)
        }

        return cell
    }
}
