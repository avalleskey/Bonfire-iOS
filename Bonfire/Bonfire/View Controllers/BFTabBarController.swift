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
        tabBar.shadowImage = UIImage() //UIImage(named: "TabBarShadow")
        tabBar.tintColor = Constants.Color.primary
        tabBar.unselectedItemTintColor = Constants.Color.secondary.withAlphaComponent(0.5)
        tabBar.itemWidth = 80
        tabBar.itemPositioning = .centered
        tabBar.itemSpacing = 2

        hero.isEnabled = false

        delegate = self
    }
}

extension BFTabBarController: UITabBarControllerDelegate {
    func tabBarController(
        _ tabBarController: UITabBarController, shouldSelect viewController: UIViewController
    ) -> Bool {
        let child = (viewController as? UINavigationController)?.topViewController

        if !(child is FeedViewController) {
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
