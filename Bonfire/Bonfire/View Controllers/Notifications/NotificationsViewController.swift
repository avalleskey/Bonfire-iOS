//
//  NotificationsViewController.swift
//  Bonfire
//
//  Created by Austin Valleskey on 24/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import BFCore
import UIKit
import Cartography

final class NotificationsViewController: BaseViewController {    
    private let tableView: UITableView = .make(cellReuseIdentifier: NotificationTableViewCell.reuseIdentifier, cellClass: NotificationTableViewCell.self, topOffset: NavigationBar.coreHeight)
    private let loadingIndicator = UIActivityIndicatorView(style: .whiteLarge, color: .secondaryText, isAnimating: true, hidesWhenStopped: true)
    private let emptyStateMessageView = EmptyStateMessageView(title: "No Notifications")
    private var notifications: [UserActivity] = []
    private let controller = NotificationController()

    init() {
        super.init(navigationBar: NavigationBar(color: Constants.Color.navigationBar, rightButtonType: .more, title: "Notifications", hideOnScroll: false, showPullTab: true), scrollView: tableView)
        
        navigationBar.rightButtonAction = {
            let token: String = UserDefaults.standard.string(forKey: "DeviceToken") ?? ""

            let alert = UIAlertController(title: "APNS Token", message: token, preferredStyle: .actionSheet)
            alert.modalPresentationStyle = .popover

            let copyAction = UIAlertAction(
                title: "Copy Token", style: .default,
                handler: { (action) in
                    UIPasteboard.general.string = token
                })
            alert.addAction(copyAction)

            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

            self.present(alert, animated: true, completion: nil)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Constants.Color.systemBackground
        setUpTableView()
        setUpLoadingIndicator()
        setUpEmptyStateMessageView()
        refreshData()
    }

    private func setUpTableView() {
        view.addSubview(tableView)
        constrain(tableView) {
            $0.top == $0.superview!.safeAreaLayoutGuide.top
            $0.leading == $0.superview!.leading
            $0.trailing == $0.superview!.trailing
            $0.bottom == $0.superview!.bottom
        }

        tableView.alpha = 0
        tableView.dataSource = self
    }

    private func setUpLoadingIndicator() {
        view.addSubview(loadingIndicator)
        constrain(loadingIndicator) {
            $0.centerX == $0.superview!.centerX
            $0.centerY == $0.superview!.centerY
        }
    }

    private func setUpEmptyStateMessageView() {
        view.addSubview(emptyStateMessageView)
        constrain(emptyStateMessageView) {
            $0.centerX == $0.superview!.centerX
            $0.leading >= $0.superview!.leading + 16
            $0.trailing <= $0.superview!.trailing - 16
            $0.centerY == $0.superview!.centerY + (NavigationBar.coreHeight / 2)
        }

        emptyStateMessageView.alpha = 0
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        refreshData()
    }
    
    private func refreshData() {
        if self.notifications.count == 0 {
            loadingIndicator.startAnimating()
        }

        controller.getNotifications { notifications in
            DispatchQueue.main.async {
                self.notifications = notifications
                self.tableView.reloadData()
                
                UIView.animate(withDuration: 0.2, animations: {
                    if notifications.isEmpty {
                        self.emptyStateMessageView.alpha = 1.0
                    } else {
                        self.tableView.alpha = 1.0
                        self.tableView.transform = .identity
                    }
                    self.loadingIndicator.alpha = 0.0
                    self.loadingIndicator.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
                }, completion: nil)
            }
        }
    }

}

extension NotificationsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        notifications.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell =
            tableView.dequeueReusableCell(
                withIdentifier: NotificationTableViewCell.reuseIdentifier,
                for: indexPath) as! NotificationTableViewCell

        let notification = notifications[indexPath.row]
        cell.updateWithNotification(notification: notification)

        return cell
    }
}
