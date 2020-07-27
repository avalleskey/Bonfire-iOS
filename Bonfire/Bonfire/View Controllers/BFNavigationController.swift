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

    private let bfNavigationItem: UINavigationItem = {
        let item = UINavigationItem()
        let profileImage = RoundedImageView(image: UIImage(named: "Austin"))
        profileImage.heightAnchor.constraint(equalToConstant: 34).isActive = true
        profileImage.widthAnchor.constraint(equalToConstant: 34).isActive = true
        item.leftBarButtonItem = .init(customView: profileImage)
        item.rightBarButtonItem = .init(
            barButtonSystemItem: .bookmarks,
            target: self,
            action: nil)

        return item
    }()

    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        delegate = self
        hero.isEnabled = true

        // style
        //        if #available(iOS 11.0, *) {
        //            additionalSafeAreaInsets.top = navigationBarHeight - navigationBar.frame.size.height
        //        }

        navigationBar.barTintColor = Constants.Color.navigationBar
        navigationBar.isTranslucent = false
        navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationBar.shadowImage = UIImage()
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

        viewController.navigationItem.leftBarButtonItem = bfNavigationItem.leftBarButtonItem
        viewController.navigationItem.rightBarButtonItem = bfNavigationItem.rightBarButtonItem

        switch viewController {
        case is HomeViewController:
            let icon = UIImage(named: "HomeNavIcon")?.withRenderingMode(
                UIImage.RenderingMode.alwaysTemplate)
            viewController.navigationItem.rightBarButtonItem = .init(
                image: icon,
                style: .plain,
                target: nil,
                action: #selector(openNotifications))
            viewController.navigationItem.rightBarButtonItem?.tintColor = Constants.Color.primary
        case is FriendsViewController:
            let icon = UIImage(named: "FriendsNavIcon")?.withRenderingMode(
                UIImage.RenderingMode.alwaysTemplate)
            viewController.navigationItem.rightBarButtonItem = .init(
                image: icon,
                style: .plain,
                target: nil,
                action: nil)
            viewController.navigationItem.rightBarButtonItem?.tintColor = Constants.Color.primary

        case is CampsViewController:
            let icon = UIImage(named: "MoreNavIcon")?.withRenderingMode(
                UIImage.RenderingMode.alwaysTemplate)
            viewController.navigationItem.rightBarButtonItem = .init(
                image: icon,
                style: .plain,
                target: nil,
                action: nil)
            viewController.navigationItem.rightBarButtonItem?.tintColor = Constants.Color.primary
        default:
            break
        }
    }
    
    @objc private func openNotifications() {
        let notificationsViewController = NotificationsViewController()
        let notificationsNavController = UINavigationController(rootViewController: notificationsViewController)
        self.present(notificationsNavController, animated: true)
    }
}
