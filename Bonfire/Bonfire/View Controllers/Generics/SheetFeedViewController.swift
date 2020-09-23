//
//  SheetFeedViewController.swift
//  Bonfire
//
//  Created by Austin Valleskey on 2020-08-19.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import BFCore
import UIKit
import Cartography

protocol SheetFeedViewControllerDelegate: AnyObject {
    func tableViewDidScroll(_ tableView: UITableView)
}

class SheetFeedViewController: BaseViewController {
    
    weak var delegate: SheetFeedViewControllerDelegate?
    
    let tableView: UITableView = .make(cellReuseIdentifier: FeedCell.reuseIdentifier, cellClass: FeedCell.self)
    let loadingIndicator = UIActivityIndicatorView(style: .whiteLarge, color: .secondaryText, isAnimating: true, hidesWhenStopped: true)
    let emptyStateMessageView = EmptyStateMessageView(title: "Nothing to show", subtitle: "Start by joining some camps!")
    var posts: [Post] = []
    
    init(title: String? = "Fires") {
        super.init(navigationBar: NavigationBar(color: Constants.Color.groupedBackground, leftButtonType: .none, rightButtonType: .bell, title: title, hideOnScroll: false, showPullTab: true), scrollView: tableView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Constants.Color.groupedBackground
        setUpTableView()
        setUpLoadingIndicator()
        setUpEmptyStateMessageView()
    }

    private func setUpTableView() {
        tableView.backgroundColor = view.backgroundColor
        view.addSubview(tableView)
        constrain(tableView) {
            $0.top == $0.superview!.safeAreaLayoutGuide.top
            $0.leading == $0.superview!.leading
            $0.trailing == $0.superview!.trailing
            $0.bottom == $0.superview!.bottom
        }

        tableView.alpha = 0
        tableView.dataSource = self
        tableView.isScrollEnabled = false
    }

    private func setUpLoadingIndicator() {
        view.addSubview(loadingIndicator)
        constrain(loadingIndicator) {
            $0.centerX == $0.superview!.centerX
            $0.centerY == $0.superview!.centerY - 24
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

    func refreshData() {
        
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == tableView {
            delegate?.tableViewDidScroll(tableView)
        }
        
        super.scrollViewDidScroll(scrollView)
    }
}

extension SheetFeedViewController: BFFloatingButtonDelegate {
    func floatingButtonTapped() {
        print("open compose")
    }
}

extension SheetFeedViewController: FeedCellDelegate {
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

extension SheetFeedViewController: UITableViewDelegate, UITableViewDataSource {
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
            cell.style = .rounded
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "BlankCell", for: indexPath)
        return cell
    }
}
