//
//  CampViewController.swift
//  Bonfire
//
//  Created by James Dale on 31/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import BFCore
import UIKit
import Cartography

final class CampViewController: BaseViewController, CustomPresentable {
    var transitionManager: UIViewControllerTransitioningDelegate?

    var camp: Camp! {
        didSet {
            campUpdated()
        }
    }
    
    private let tableView: UITableView = .make(cellReuseIdentifier: "Cell", cellClass: UITableViewCell.self, topOffset: NavigationBar.coreHeight)
    private let loadingIndicator = UIActivityIndicatorView(style: .whiteLarge, color: .secondaryText, isAnimating: true, hidesWhenStopped: true)
    private let emptyStateMessageView = EmptyStateMessageView(title: "CampViewController")
    private var posts: [Post] = []
    private let controller = CampController()

    init(camp: Camp) {
        self.camp = camp
        super.init(navigationBar: NavigationBar(color: Constants.Color.systemBackground, leftButtonType: .back, rightButtonType: .more), scrollView: tableView)
        
        navigationBar.leftButtonAction = {
            self.navigationController?.popViewController(animated: true)
        }
        navigationBar.rightButtonAction = {
            self.dismiss(animated: true, completion: nil)
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
        campUpdated()
    }
    
    func campUpdated() {
        tableView.reloadData()
        
        view.backgroundColor = UIColor(hex: camp.attributes.color) ?? Constants.Color.secondary
        tableView.backgroundColor = UIColor(hex: camp.attributes.color) ?? Constants.Color.secondary
        
        navigationBar.color = UIColor(hex: camp.attributes.color) ?? Constants.Color.secondary
        
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        let darkBackground = navigationBar.backgroundColor?.isDarkColor ?? false
        return darkBackground ? .lightContent : .default
    }
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .fade
    }

    private func setUpTableView() {
        view.addSubview(tableView)
        constrain(tableView) {
            $0.top == $0.superview!.safeAreaLayoutGuide.top
            $0.leading == $0.superview!.leading
            $0.trailing == $0.superview!.trailing
            $0.bottom == $0.superview!.bottom
        }

        tableView.alpha = 1
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

        emptyStateMessageView.alpha = 0
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

extension CampViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        3
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        cell.backgroundColor = .clear
        switch indexPath.row {
            case 0:
                cell.textLabel?.text = String("Camp: \(camp.id)")
            case 1:
                cell.textLabel?.text = String("Title: \(camp.attributes.title)")
            case 2:
                cell.textLabel?.text = String("Description: \(camp.attributes.description)")
            default:
                break
        }
        
        return cell
    }
}
