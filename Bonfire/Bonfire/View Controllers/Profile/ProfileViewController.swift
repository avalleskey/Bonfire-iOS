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

final class ProfileViewController: SplitViewController<ProfileHeaderView, ProfileSheetViewController> {
    
    private let profiles = ProfileController()
    
    var user: User? {
        didSet {
            DispatchQueue.main.async {
                self.userUpdated()
            }
        }
    }

    init(user: User?) {
        self.user = user
        super.init(headerView: ProfileHeaderView(), sheetViewController: ProfileSheetViewController(userId: user?.id ?? user?.attributes.identifier ?? ""), navigationBar: NavigationBar(color: Constants.Color.navigationBar, leftButtonType: .back, rightButtonType: .more, title: "", subtitle: ""), scrollView: nil)
        
        navigationBar.leftButtonAction = {
            self.navigationController?.popViewController(animated: true)
        }
        navigationBar.rightButtonAction = {
            let options = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
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
        
        updateWithColor(user?.attributes.color, animated: false)
    }
    
    override func setUpHeaderView() {
        super.setUpHeaderView()
        headerView.user = user
    }
    
    override func setUpSheet() {
        super.setUpSheet()
        
        sheetViewController.navigationBar.rightButtonAction = {
            var message: String?
            if let displayName = self.user?.attributes.displayName {
                message = "When \(displayName) talks, notify me"
            }
            let options = UIAlertController(title: nil, message: message, preferredStyle: .actionSheet)

            let checkString = " ✓"
            let viewProfile = UIAlertAction(
                title: "Always\(false ? checkString : "")", style: .default,
                handler: { (action) in
                    
                })
            options.addAction(viewProfile)
            
            let leave = UIAlertAction(
                title: "Sometimes\(true ? checkString : "")", style: .default,
                handler: { (action) in
                    
                })
            options.addAction(leave)
            
            let report = UIAlertAction(
                title: "Never\(false ? checkString : "")", style: .default,
                handler: { (action) in
                    
                })
            options.addAction(report)

            options.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(options, animated: true, completion: nil)
        }
    }

    override func loadData() {
        if let userId = user?.id {
            self.profiles.getUser(user: userId) { user in
                DispatchQueue.main.async {
                    self.user = user
                }
            }
        }
    }
    
    private func userUpdated() {
        headerView.user = user
        updateWithColor(user?.attributes.color, animated: true)
        navigationBar.title = user?.attributes.displayName ?? nil
        var subtitle: String?
        if let statusEmoji = user?.attributes.statusEmoji {
            subtitle?.append(statusEmoji)
        }
        if let statusString = user?.attributes.statusString {
            subtitle?.append(" \(statusString)")
        }
        navigationBar.subtitle = subtitle ?? nil
        
        if sheetState == .collapsed {
            self.sheetTopConstraint?.constant = self.collapsedHeight
            
            UIView.animate(
                withDuration: 0.4,
                delay: 0,
                usingSpringWithDamping: 0.9,
                initialSpringVelocity: 3,
                options: [.curveEaseInOut],
                animations: {
                    self.view.layoutIfNeeded()
                })
        }
    }
}
