//
//  CampsViewController.swift
//  Bonfire
//
//  Created by James Dale on 20/6/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation
import UIKit

final class CampsViewController: UIViewController {

    static var defaultTabBarItem: UITabBarItem {
        UITabBarItem(
            title: Constants.TabBar.campsDefaultText,
            image: Constants.TabBar.campsDefaultImage,
            tag: 2)
    }

    private let activityIndicator: UIActivityIndicatorView = {
        var indicator = UIActivityIndicatorView(style: .whiteLarge)
        indicator.color = Constants.Color.secondary
        return indicator
    }()
    private let campsTableView = CampsTableViewController()
    private let controller = CampController()

    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) { view.backgroundColor = .systemBackground }

        view.addSubview(campsTableView.view)
        view.addSubview(activityIndicator)

        refresh()

        updateViewConstraints()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refresh()
    }
    
    private func refresh() {
        activityIndicator.startAnimating()
        controller.getCamps { (camps) in
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.campsTableView.camps = camps
                self.campsTableView.tableView.reloadData()
            }
        }
    }

    override func updateViewConstraints() {
        super.updateViewConstraints()

        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        campsTableView.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            campsTableView.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            campsTableView.view.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            campsTableView.view.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            campsTableView.view.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor),
        ])
    }

}
