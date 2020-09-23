//
//  FeedViewController.swift
//  Bonfire
//
//  Created by Daniel Gauthier on 2020-08-19.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import BFCore
import UIKit
import Cartography

final class MessageViewController: BaseViewController {
    private let tableView: UITableView = .make(cellReuseIdentifier: "Cell", cellClass: UITableViewCell.self, topOffset: NavigationBar.coreHeight)
    private let loadingIndicator = UIActivityIndicatorView(style: .whiteLarge, color: .secondaryText, isAnimating: true, hidesWhenStopped: true)
    private let emptyStateMessageView = EmptyStateMessageView(title: "MessageViewController")
    private var posts: [Post] = []
    private let controller = StreamController()

    init() {
        super.init(navigationBar: NavigationBar(color: Constants.Color.navigationBar, leftButtonType: .back, rightButtonType: .custom(image: .dummyAvatar), title: "Display Name", subtitle: "👀 User's Status"), scrollView: tableView)
        
        navigationBar.leftButtonAction = {
            self.navigationController?.popViewController(animated: true)
        }
        navigationBar.centerButtonAction = {
            // open their profile
        }
        navigationBar.rightButtonAction = {
            let options = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

            let viewProfile = UIAlertAction(
                title: "View Profile 👤", style: .default,
                handler: { (action) in
                    
                })
            options.addAction(viewProfile)
            
            let leave = UIAlertAction(
                title: "Leave ✌️", style: .default,
                handler: { (action) in
                    
                })
            options.addAction(leave)
            
            let report = UIAlertAction(
                title: "Report ✋", style: .destructive,
                handler: { (action) in
                    
                })
            options.addAction(report)

            options.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(options, animated: true, completion: nil)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Constants.Color.systemBackground
        setUpTableView()
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

    private func setUpEmptyStateMessageView() {
        view.addSubview(emptyStateMessageView)
        constrain(emptyStateMessageView) {
            $0.centerX == $0.superview!.centerX
            $0.leading >= $0.superview!.leading + 16
            $0.trailing <= $0.superview!.trailing - 16
            $0.centerY == $0.superview!.centerY + (NavigationBar.coreHeight / 2)
        }

//        emptyStateMessageView.alpha = 0
    }

    private func refreshData() {
//        controller.getStream { posts in
//            DispatchQueue.main.async {
//                self.posts = posts
//                self.tableView.reloadData()
//                UIView.animate(withDuration: 0.2, animations: {
//                    if posts.isEmpty {
//                        self.emptyStateMessageView.alpha = 1.0
//                    } else {
//                        self.tableView.alpha = 1.0
//                    }
//                    self.loadingIndicator.alpha = 0.0
//                }, completion: nil)
//            }
//        }
    }
}

extension MessageViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        return cell
    }
}
