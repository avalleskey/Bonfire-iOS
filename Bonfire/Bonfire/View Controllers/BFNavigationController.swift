//
//  BFNavigationController.swift
//  Bonfire
//
//  Created by James Dale on 22/6/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation
import Hero
import UIKit

final class BFNavigationController: UINavigationController {
    var navigationBarHeight: CGFloat = 52

    private let currentUserNavigationItem: UINavigationItem = {
        let item = UINavigationItem()
        let profileImage = RoundedImageView(image: UIImage(named: "Austin"))
        profileImage.heightAnchor.constraint(equalToConstant: 34).isActive = true
        profileImage.widthAnchor.constraint(equalToConstant: 34).isActive = true
        item.leftBarButtonItem = .init(customView: profileImage)

        return item
    }()

    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        delegate = self
        hero.isEnabled = true

        navigationBar.barTintColor = Constants.Color.navigationBar
        navigationBar.isTranslucent = false
        navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationBar.shadowImage = UIImage()
        
        let titleFont = UIFont.systemFont(ofSize: 20, weight: .bold).rounded()
        navigationBar.titleTextAttributes = [NSAttributedString.Key.font: titleFont]
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension BFNavigationController: UINavigationControllerDelegate {
    func navigationController(
        _ navigationController: UINavigationController, willShow viewController: UIViewController,
        animated: Bool
    ) {
        
        switch viewController {
        case is HomeViewController:
            viewController.navigationItem.leftBarButtonItem = currentUserNavigationItem.leftBarButtonItem
            
            let rightIcon = UIImage(named: "ComposeNavIcon")?.withRenderingMode(
                UIImage.RenderingMode.alwaysTemplate)
            viewController.navigationItem.rightBarButtonItem = .init(
                image: rightIcon,
                style: .plain,
                target: nil,
                action: #selector(compose))
            
            viewController.navigationItem.rightBarButtonItem?.tintColor = Constants.Color.primary
        case is FriendsViewController:
            viewController.navigationItem.leftBarButtonItem = currentUserNavigationItem.leftBarButtonItem
            
            let rightIcon = UIImage(named: "PlusNavIcon")?.withRenderingMode(
                UIImage.RenderingMode.alwaysTemplate)
            viewController.navigationItem.rightBarButtonItem = .init(
                image: rightIcon,
                style: .plain,
                target: nil,
                action: #selector(openAddFriends))
            viewController.navigationItem.rightBarButtonItem?.tintColor = Constants.Color.primary

        case is CampsViewController:
            viewController.navigationItem.leftBarButtonItem = currentUserNavigationItem.leftBarButtonItem
            
            let rightIcon = UIImage(named: "PlusNavIcon")?.withRenderingMode(
                UIImage.RenderingMode.alwaysTemplate)
            viewController.navigationItem.rightBarButtonItem = .init(
                image: rightIcon,
                style: .plain,
                target: nil,
                action: #selector(openAddCamps))
            viewController.navigationItem.rightBarButtonItem?.tintColor = Constants.Color.primary
        default:
            break
        }
    }

    @objc private func openNotifications() {
        let notificationsViewController = NotificationsViewController()
        let notificationsNavController = UINavigationController(
            rootViewController: notificationsViewController)
        self.present(notificationsNavController, animated: true)
    }
    
    @objc func openAddFriends() {
        let items: [Any] = [
            "Add me on Bonfire! 🔥", URL(string: "https://www.bonfire.camp/u/austin")!,
        ]
        let ac = UIActivityViewController(activityItems: items, applicationActivities: nil)
        present(ac, animated: true)
    }
    @objc func openAddCamps() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.view.tintColor = Constants.Color.primary

        let createCampAction = UIAlertAction(
            title: "Create Camp", style: .default,
            handler: { (action) in
                print("create camp!")
            })
        if #available(iOS 13.0, *) {
            createCampAction.setValue(UIImage(systemName: "plus"), forKey: "image")
        }
        alert.addAction(createCampAction)

        let discoverCampsAction = UIAlertAction(
            title: "Discover Camps", style: .default,
            handler: { (action) in
                print("discover camps!")
            })
        if #available(iOS 13.0, *) {
            discoverCampsAction.setValue(UIImage(systemName: "safari"), forKey: "image")
        }
        alert.addAction(discoverCampsAction)

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    @objc func compose() {
        present(CreatePostViewController(), animated: true)
    }
}
