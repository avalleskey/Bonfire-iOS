//
//  BFTabBarController.swift
//  Bonfire
//
//  Created by James Dale on 21/6/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import BFNetworking
import Hero
import UIKit

final class BFTabBarController: UITabBarController {

    override var selectedViewController: UIViewController? {
        didSet {
            if oldValue == selectedViewController {
                // scroll to top
                selectedViewController!.scrollToTop()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tabBar.backgroundColor = Constants.Color.tabBar
        tabBar.isTranslucent = false
        tabBar.barTintColor = Constants.Color.tabBar
        tabBar.backgroundImage = UIImage()
        tabBar.shadowImage = UIImage(named: "TabBarShadow")
        tabBar.tintColor = Constants.Color.primary
        tabBar.unselectedItemTintColor = Constants.Color.secondary

        let tabBarItemFont = UIFont.systemFont(ofSize: 12, weight: .bold).rounded()
        let appearance = UITabBarItem.appearance()
        let attributes = [NSAttributedString.Key.font: tabBarItemFont]
        appearance.setTitleTextAttributes(attributes, for: .normal)
        appearance.titlePositionAdjustment = .init(horizontal: 0, vertical: -5)

        hero.isEnabled = false

        delegate = self
    }

    override func viewDidLayoutSubviews() {
        super.viewWillLayoutSubviews()
        //        custom tab bar height
        //        tabBar.frame.size.height = 58
        //        tabBar.frame.origin.y = view.frame.height - 58
    }
}

extension BFTabBarController: UITabBarControllerDelegate {
    func tabBarController(
        _ tabBarController: UITabBarController, shouldSelect viewController: UIViewController
    ) -> Bool {
        let child = (viewController as? UINavigationController)?.topViewController

        if child is CampsViewController || child is FriendsViewController {
            if KeychainVault.accessToken == nil {
                let authController = GetStartedViewController()
                let authNavcontroller = GetStartedNavigationController(
                    rootViewController: authController)
                self.present(authNavcontroller, animated: true)
                return false
            }
        }

        return true
    }
}
