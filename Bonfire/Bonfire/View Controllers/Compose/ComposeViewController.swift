//
//  ComposeViewController.swift
//  Bonfire
//
//  Created by Austin Valleskey on 24/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import BFCore
import UIKit
import Cartography

final class ComposeViewController: BaseViewController {
    private let tableView: UITableView = .make(cellReuseIdentifier: SetStatusCell.reuseIdentifier, cellClass: SetStatusCell.self, topOffset: NavigationBar.coreHeight)
    private let controller = SetStatusController()

    init() {
        super.init(navigationBar: NavigationBar(color: Constants.Color.navigationBar, rightButtonType: .close, title: "Start a Fire", hideOnScroll: false, showPullTab: true), scrollView: tableView)
        
        navigationBar.rightButtonAction = {
            self.dismiss(animated: true, completion: nil)
        }
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

extension ComposeViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell =
            tableView.dequeueReusableCell(
                withIdentifier: SetStatusCell.reuseIdentifier,
                for: indexPath) as! SetStatusCell

        return cell
    }
}

extension ComposeViewController: UITableViewDelegate {
    
}
