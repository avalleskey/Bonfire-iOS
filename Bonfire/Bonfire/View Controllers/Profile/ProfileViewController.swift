//
//  ProfileViewController.swift
//  Bonfire
//
//  Created by James Dale on 29/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import BFCore
import UIKit
import Cartography

final class ProfileViewController: BaseViewController {

    private let tableView: UITableView = .make(cellReuseIdentifier: FeedCell.reuseIdentifier, cellClass: FeedCell.self, topOffset: 0)
    private let loadingIndicator = UIActivityIndicatorView(style: .whiteLarge, color: .secondaryText, isAnimating: true, hidesWhenStopped: true)
    private let emptyStateMessageView = EmptyStateMessageView(title: "CampViewController")
    private var posts: [Post] = []
    
    private let headerView = ProfileHeaderView()
    private let streams = StreamController()
    private let profiles = ProfileController()
    
    
    
    var user: User! {
        didSet {
            userUpdated()
        }
    }

    init(user: User? = nil) {
        self.user = user
        super.init(navigationBar: NavigationBar(color: Constants.Color.systemBackground, leftButtonType: .back, rightButtonType: .more, title: "", subtitle: ""), scrollView: nil)
        
        navigationBar.leftButtonAction = {
            self.navigationController?.popViewController(animated: true)
        }
        navigationBar.centerButtonAction = {
            // open their profile
        }
        navigationBar.rightButtonAction = {
            let options = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            options.view.tintColor = Constants.Color.brand

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
        
        updateViewConstraints()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Constants.Color.systemBackground
        setUpTableView()
        setUpLoadingIndicator()
        setUpEmptyStateMessageView()
        refreshData()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.delegate = self
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    private func setUpTableView() {
        view.addSubview(tableView)
        constrain(tableView, navigationBar) {
            $0.top >= $1.bottom
            $0.leading == $0.superview!.leading
            $0.trailing == $0.superview!.trailing
            $0.bottom == $0.superview!.bottom
            $0.height == 300
        }

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
        streams.getStream { posts in
            DispatchQueue.main.async {
                self.posts = posts
                self.tableView.reloadData()
                self.tableView.transform = CGAffineTransform(translationX: 0, y: 12)
                UIView.animate(withDuration: 0.2, animations: {
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
    
    private func userUpdated() {
        tableView.reloadData()
        
        view.backgroundColor = UIColor(hex: user.attributes.color) ?? Constants.Color.secondary
        tableView.backgroundColor = UIColor(hex: user.attributes.color) ?? Constants.Color.secondary
        
        navigationBar.color = UIColor(hex: user.attributes.color) ?? Constants.Color.secondary
        
        navigationBar.rightButtonAction = {
            let options = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            options.view.tintColor = Constants.Color.brand

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
        
        setNeedsStatusBarAppearanceUpdate()
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

extension ProfileViewController: BFFloatingButtonDelegate {
    func floatingButtonTapped() {
        print("open compose")
    }
}

extension ProfileViewController: FeedCellDelegate {
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
    func performAction() {
        
    }
    func replyButtonTapped() {
        
    }
}

extension ProfileViewController: UITableViewDataSource {
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
            cell.separatorView.isHidden = indexPath.row == posts.count - 1
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "BlankCell", for: indexPath)
        return cell
    }
}
