//
//  NewFeedViewController.swift
//  Bonfire
//
//  Created by Daniel Gauthier on 2020-08-19.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import BFCore
import UIKit
import Cartography

final class NewFeedViewController: UIViewController {

    private let navigationView = NavigationView(color: .systemBackground, leftButtonType: .status(emoji: "🥳"), rightButtonType: .bell, titleImage: .dummyAvatar)
    private let tableView: UITableView = .make(cellReuseIdentifier: FeedCell.reuseIdentifier, cellClass: FeedCell.self, topOffset: NavigationView.coreHeight)
    private var dataSource: UITableViewDiffableDataSource<Int, Post>!
    private var posts: [Post] = []
    private let controller = StreamController()

    init() {
        super.init(nibName: nil, bundle: nil)
        dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { tableView, indexPath, post -> UITableViewCell? in
            guard let cell = tableView.dequeueReusableCell(withIdentifier: FeedCell.reuseIdentifier, for: indexPath) as? FeedCell else { return nil }
            cell.post = post
            cell.delegate = self
            return cell
        })
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTableView()
        setUpNavigationView()
        refreshData()
    }

    private func setUpNavigationView() {
        view.addSubview(navigationView)
        constrain(navigationView) {
            navigationView.topConstraint = $0.top == $0.superview!.top
            $0.leading == $0.superview!.leading
            $0.trailing == $0.superview!.trailing
        }

        navigationView.managingScrollView = tableView
    }

    private func setUpTableView() {
        view.addSubview(tableView)
        constrain(tableView) {
            $0.top == $0.superview!.safeAreaLayoutGuide.top
            $0.leading == $0.superview!.leading
            $0.trailing == $0.superview!.trailing
            $0.bottom == $0.superview!.bottom
        }
    }

    private func refreshData() {
        controller.getStream { posts in
            DispatchQueue.main.async {
                self.posts = posts
                self.updateDataSource(skipAnimation: true)
            }
        }
    }

    private func updateDataSource(skipAnimation: Bool = false) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, Post>()
        snapshot.appendSections([0])
        snapshot.appendItems(posts)
        dataSource.apply(snapshot, animatingDifferences: !skipAnimation)
    }
}

extension NewFeedViewController: FeedCellDelegate {
    func performAction() {
        let testViewController = TestViewController()
        navigationController?.pushViewController(testViewController, animated: true)
    }
}
