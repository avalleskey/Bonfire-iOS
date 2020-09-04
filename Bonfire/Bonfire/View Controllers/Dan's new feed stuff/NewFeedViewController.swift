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

final class NewFeedViewController: BaseViewController {

    private let tableView: UITableView = .make(cellReuseIdentifier: FeedCell.reuseIdentifier, cellClass: FeedCell.self, topOffset: NavigationBar.coreHeight)
    private let loadingIndicator = UIActivityIndicatorView(style: .large, isAnimating: true, hidesWhenStopped: true)
    private let emptyStateMessageView = EmptyStateMessageView(title: "Nothing to show", subtitle: "Start by joining some camps!")
    private var dataSource: UITableViewDiffableDataSource<Int, Post>!
    private var posts: [Post] = []
    private let controller = StreamController()

    init() {
        super.init(navigationBar: NavigationBar(color: .systemBackground, leftButtonType: .status(emoji: "🥳"), rightButtonType: .bell, titleImage: .dummyAvatar), scrollView: tableView)
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
        view.backgroundColor = .systemBackground
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
    }

    private func setUpLoadingIndicator() {
        view.addSubview(loadingIndicator)
        constrain(loadingIndicator) {
            $0.centerX == $0.superview!.centerX
            $0.centerY == $0.superview!.centerY + (NavigationBar.coreHeight / 2)
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
        controller.getStream { posts in
            DispatchQueue.main.async {
                self.posts = posts
                self.updateDataSource(skipAnimation: true)
                UIView.animate(withDuration: 0.2, animations: {
                    if posts.isEmpty {
                        self.emptyStateMessageView.alpha = 1.0
                    } else {
                        self.tableView.alpha = 1.0
                    }
                    self.loadingIndicator.alpha = 0.0
                }, completion: nil)
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
