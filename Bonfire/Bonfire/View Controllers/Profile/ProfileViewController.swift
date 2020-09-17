//
//  ProfileViewController.swift
//  Bonfire
//
//  Created by James Dale on 29/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import BFCore
import UIKit

final class ProfileViewController: UIViewController {

    private let headerView = ProfileHeaderView()
    private let streams = StreamController()
    private let profiles = ProfileController()

    init() {
        super.init(nibName: nil, bundle: nil)

        navigationItem.title = "Profile"

        updateViewConstraints()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.delegate = self
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateViewConstraints() {
        super.updateViewConstraints()

        headerView.translatesAutoresizingMaskIntoConstraints = false
    }

    func update(user: User) {
        self.headerView.summaryPage.imageView.kf.setImage(with: user.attributes.media?.avatar?.full?.url)
        navigationItem.title = user.attributes.display_name
        let campCount = user.attributes.summaries?.counts?.camps ?? 0
        let friendCount = user.attributes.summaries?.counts?.following ?? 0
        headerView.summaryPage.primaryLabel.text = "\(campCount) camps  \(friendCount) friends"
        headerView.backgroundColor = user.attributes.uiColor
    }
    
    func load(id: String) {
        streams.getStream(user: id) { (posts) in
            DispatchQueue.main.async {
//                self.feedTableView.posts = posts
//                self.feedTableView.tableView.reloadData()
                
            }
        }
        
        profiles.getUser(user: id) { (user) in
            DispatchQueue.main.async {
                self.update(user: user)
            }
        }
    }

}

// We need this to fix a nasty issue with tab bar controller and navigation controller together
extension ProfileViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }
}
