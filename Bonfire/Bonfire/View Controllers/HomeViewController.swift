//
//  ViewController.swift
//  Bonfire
//
//  Created by James Dale on 19/6/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit

final class HomeViewController: UIKeyboardSubscribedViewController {

    private let segmentedControl = BFSegmentedControl()

    static var defaultTabBarItem: UITabBarItem {
        let item = UITabBarItem(
            title: Constants.TabBar.homeDefaultText,
            image: Constants.TabBar.homeDefaultImage,
            selectedImage: Constants.TabBar.homeDefaultImage)
        item.tag = 1
        return item
    }

    private let activityIndicator: UIActivityIndicatorView = {
        var indicator = UIActivityIndicatorView(style: .whiteLarge)
        indicator.color = Constants.Color.secondary
        return indicator
    }()
    private let homeFeedTableView = BFFeedTableViewController()
    private let controller = StreamController()

    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) { view.backgroundColor = .systemBackground }

        addChild(homeFeedTableView)
        view.addSubview(homeFeedTableView.view)
        view.addSubview(activityIndicator)

        segmentedControl.addItem(.init(title: "Following", target: nil, action: nil))
        segmentedControl.addItem(.init(title: "For You", target: nil, action: nil))

        navigationItem.titleView = segmentedControl
        homeFeedTableView.enableConversationView = true

        refresh()
        subscribeToKeyboard()

        updateViewConstraints()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refresh()
    }

    private func refresh() {
        if self.homeFeedTableView.posts.count == 0 {
            activityIndicator.startAnimating()
        }
        
        controller.getStream { (posts) in
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                
                self.homeFeedTableView.posts = posts
                self.homeFeedTableView.tableView.reloadData()
            }
        }
    }

    override func updateViewConstraints() {
        super.updateViewConstraints()

        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        homeFeedTableView.view.translatesAutoresizingMaskIntoConstraints = false

        keyboardConstraints.append(
            homeFeedTableView.view.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor))

        keyboardConstraints.forEach { $0.isActive = true }

        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            homeFeedTableView.view.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor),
            homeFeedTableView.view.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            homeFeedTableView.view.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor),
        ])
    }

}
