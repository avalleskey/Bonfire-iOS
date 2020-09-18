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

final class SetStatusViewController: BaseViewController {    
    private let tableView: UITableView = .make(cellReuseIdentifier: SetStatusCell.reuseIdentifier, cellClass: SetStatusCell.self, topOffset: NavigationBar.coreHeight)
    private let controller = SetStatusController()

    init() {        
        super.init(navigationBar: NavigationBar(color: Constants.Color.systemBackground, title: "My Status", hideOnScroll: false, showPullTab: true), scrollView: tableView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Constants.Color.systemBackground
        setUpTableView()
    }

    private func setUpTableView() {
        view.addSubview(tableView)
        constrain(tableView) {
            $0.top == $0.superview!.safeAreaLayoutGuide.top
            $0.leading == $0.superview!.leading
            $0.trailing == $0.superview!.trailing
            $0.bottom == $0.superview!.bottom
        }

        tableView.dataSource = self
        tableView.delegate = self
    }

}

extension SetStatusViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        60
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        4
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell =
            tableView.dequeueReusableCell(
                withIdentifier: SetStatusCell.reuseIdentifier,
                for: indexPath) as! SetStatusCell

        switch indexPath.row {
            case 0:
                cell.emoji = "💬"
                cell.status = "I want to chat!"
            case 1:
                cell.emoji = "👀"
                cell.status = "Looking to make new friends"
            case 2:
                cell.emoji = "🚶"
                cell.status = "Out and about"
            case 3:
                cell.emoji = "🤗"
                cell.status = "Happy camper :)"
            default:
                break
        }

        return cell
    }
}

extension SetStatusViewController: UITableViewDelegate {
    
}
