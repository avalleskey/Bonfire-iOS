//
//  NewFeedViewController.swift
//  Bonfire
//
//  Created by Daniel Gauthier on 2020-08-19.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit
import Cartography

final class NewFeedViewController: UIViewController {

    private let tableView: UITableView = .make(cellReuseIdentifier: FeedCell.reuseIdentifier, cellClass: FeedCell.self)
    private var dataSource: UITableViewDiffableDataSource<Int, DummyPost>!
    private let posts = DummyPost.testData

    init() {
        super.init(nibName: nil, bundle: nil)
        dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { tableView, indexPath, post -> UITableViewCell? in
            guard let cell = tableView.dequeueReusableCell(withIdentifier: FeedCell.reuseIdentifier, for: indexPath) as? FeedCell else { return nil }
            cell.post = post
            return cell
        })
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemPink
        navigationItem.title = Constants.TabBar.homeDefaultText

        setUpTableView()
        updateDataSource()
    }

    private func setUpTableView() {
        view.addSubview(tableView)
        constrain(tableView) {
            $0.edges == $0.superview!.edges
        }
    }

    private func updateDataSource(skipAnimation: Bool = false) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, DummyPost>()
        snapshot.appendSections([0])
        snapshot.appendItems(posts)
        dataSource.apply(snapshot, animatingDifferences: !skipAnimation)
    }
}
