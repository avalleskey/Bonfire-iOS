//
//  ViewController.swift
//  Bonfire
//
//  Created by James Dale on 19/6/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit

final class HomeViewController: UIViewController {

    let segmentedControl = BFSegmentedControl()

    static var defaultTabBarItem: UITabBarItem {
        let item = UITabBarItem(
            title: Constants.TabBar.homeDefaultText,
            image: Constants.TabBar.homeDefaultImage,
            selectedImage: Constants.TabBar.homeDefaultImage)
        item.tag = 1
        return item
    }

    let homeFeedTableView = BFFeedTableViewController()
    let controller = StreamController()

    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) { view.backgroundColor = .systemBackground }

        view.addSubview(homeFeedTableView.view)

        segmentedControl.addItem(.init(title: "Following", target: nil, action: nil))
        segmentedControl.addItem(.init(title: "For You", target: nil, action: nil))

        navigationItem.titleView = segmentedControl
        
        refresh()

        updateViewConstraints()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refresh()
    }
    
    private func refresh() {
        controller.getStream { (posts) in
            DispatchQueue.main.async {
                self.homeFeedTableView.posts = posts
                self.homeFeedTableView.tableView.reloadData()
            }
        }
    }

    override func updateViewConstraints() {
        super.updateViewConstraints()

        homeFeedTableView.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            homeFeedTableView.view.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor),
            homeFeedTableView.view.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            homeFeedTableView.view.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            homeFeedTableView.view.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor),
        ])
    }

}
