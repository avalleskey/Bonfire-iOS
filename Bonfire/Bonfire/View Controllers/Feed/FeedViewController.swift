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

final class FeedViewController: BaseViewController {

    private let tableView: UITableView = .make(cellReuseIdentifier: FeedCell.reuseIdentifier, cellClass: FeedCell.self, topOffset: NavigationBar.coreHeight)
    private let loadingIndicator = UIActivityIndicatorView(style: .whiteLarge, color: .secondaryText, isAnimating: true, hidesWhenStopped: true)
    private let emptyStateMessageView = EmptyStateMessageView(title: "Nothing to show", subtitle: "Start by joining some camps!")
    private var posts: [Post] = []
    private let controller = StreamController()

    init() {
        super.init(navigationBar: NavigationBar(color: Constants.Color.navigationBar, leftButtonType: .status(emoji: "🥳"), rightButtonType: .bell, titleImage: .dummyAvatar), scrollView: tableView, floatingButton: BFFloatingButton(icon: UIImage(named: "ComposeIcon")))
        
        floatingButton?.delegate = self
        
        navigationBar.leftButtonAction = {
            let setStatusViewController = SetStatusViewController()
            self.present(setStatusViewController, customPresentationType: .sheet(customHeight: 668), tapToDismiss: true)
        }
        navigationBar.centerButtonAction = {
            let profileViewController = ProfileViewController(user: User(username: "austin"))
            self.navigationController?.pushViewController(profileViewController, animated: true)
        }
        navigationBar.rightButtonAction = {
            let notificationsViewController = NotificationsViewController()
            self.present(notificationsViewController, customPresentationType: .sheet(), tapToDismiss: true)
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
        controller.getStream { posts in
            DispatchQueue.main.async {
                self.posts = posts
                self.tableView.reloadData()
                self.tableView.transform = CGAffineTransform(translationX: 0, y: 24)
                
                UIView.animate(withDuration: 0.6, delay: 0.0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .allowUserInteraction, animations: {
                    if posts.isEmpty {
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

extension FeedViewController: BFFloatingButtonDelegate {
    func floatingButtonTapped() {
        let composeViewController = ComposeViewController()
        self.present(composeViewController, customPresentationType: .present)
    }
}

extension FeedViewController: FeedCellDelegate {
    func moreButtonTapped() {
        let options = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let report = UIAlertAction(
            title: "Report ✋", style: .destructive,
            handler: { (action) in
                
            })
        options.addAction(report)
        
        let mute = UIAlertAction(
            title: "Mute 🔕", style: .default,
            handler: { (action) in
                
            })
        options.addAction(mute)

        let copyLink = UIAlertAction(
            title: "Copy Link 🔗", style: .default,
            handler: { (action) in
                
            })
        options.addAction(copyLink)
        
        let shareTo = UIAlertAction(
            title: "Share to... 📣", style: .default,
            handler: { (action) in
                
            })
        options.addAction(shareTo)

        options.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(options, animated: true, completion: nil)
    }
    func openUser(user: User) {
        let vc = ProfileViewController(user: user)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    func openCamp(camp: Camp) {
        let vc = CampViewController(camp: camp)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    func performAction() {
        
    }
    func replyButtonTapped() {
        
    }
}

extension FeedViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
            case 0:
                return posts.count
            default:
                return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: FeedCell.reuseIdentifier, for: indexPath) as! FeedCell
            cell.type = .post(post: posts[indexPath.row])
            cell.delegate = self
//            cell.separatorView.isHidden = indexPath.row == posts.count - 1
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "BlankCell", for: indexPath)
        return cell
    }
}
