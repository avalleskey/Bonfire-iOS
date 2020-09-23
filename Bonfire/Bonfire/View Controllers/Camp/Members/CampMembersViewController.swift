//
//  SetStatusViewController.swift
//  Bonfire
//
//  Created by Austin Valleskey on 24/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import BFCore
import UIKit
import Cartography

final class CampMembersViewController: BaseViewController {
    private let tableView: UITableView = .make(cellReuseIdentifier: CampMemberCell.reuseIdentifier, cellClass: CampMemberCell.self, allowsSelection: true, topOffset: NavigationBar.coreHeight)
    private let loadingIndicator = UIActivityIndicatorView(style: .whiteLarge, color: .secondaryText, isAnimating: true, hidesWhenStopped: true)
    private let emptyStateMessageView = EmptyStateMessageView(title: "Nothing to show", subtitle: "Start by joining some camps!")
    private var users: [User] = []
    private let controller = CampController()
    
    var camp: Camp?
    
    init(camp: Camp) {
        self.camp = camp
        super.init(navigationBar: NavigationBar(color: Constants.Color.navigationBar, leftButtonType: .back, title: "Members", subtitle: self.camp?.attributes.title, hideOnScroll: true, showPullTab: false), scrollView: tableView)
        
        navigationBar.leftButtonAction = {
            self.navigationController?.popViewController(animated: true)
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

    private func refreshData() {
        if let campId = camp?.id {
            controller.getCampMembers(campId: campId) { (users) in
                DispatchQueue.main.async {
                    self.users = users
                    self.tableView.reloadData()
                    self.tableView.transform = CGAffineTransform(translationX: 0, y: 24)
                    
                    UIView.animate(withDuration: 0.6, delay: 0.0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .allowUserInteraction, animations: {
                        if users.isEmpty {
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

}

extension CampMembersViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        users.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell =
            tableView.dequeueReusableCell(
                withIdentifier: CampMemberCell.reuseIdentifier,
                for: indexPath) as! CampMemberCell
        cell.user = users[indexPath.row]

        return cell
    }
}

extension CampMembersViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let user = users[indexPath.row]
        let vc = ProfileViewController(user: user)
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
