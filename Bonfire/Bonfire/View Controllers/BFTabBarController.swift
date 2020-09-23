//
//  BFTabBarController.swift
//  Bonfire
//
//  Created by James Dale on 21/6/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import BFNetworking
import UIKit
import Cartography

final class BFTabBarController: UITabBarController {
    
    private let tabBarBlurredBackgroundView: UIVisualEffectView = {
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
        blurView.backgroundColor = Constants.Color.tabBar
        return blurView
    }()
    
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
        
        let separator = UIView(backgroundColor: Constants.Color.tabBarSeparator)
        tabBar.addSubview(separator)
        constrain(separator) {
            $0.width == $0.superview!.width
            $0.height == (1 / UIScreen.main.scale)
            $0.bottom == $0.superview!.top
        }
        
        tabBar.insertSubview(tabBarBlurredBackgroundView, at: 0)
        constrain(tabBarBlurredBackgroundView) {
            $0.edges == $0.superview!.edges
        }
        
        tabBar.backgroundColor = .clear //Constants.Color.tabBar
        tabBar.isTranslucent = true
        tabBar.barTintColor = .clear //Constants.Color.tabBar
        tabBar.backgroundImage = UIImage()
        tabBar.shadowImage = UIImage()
        tabBar.tintColor = Constants.Color.primary
        tabBar.unselectedItemTintColor = Constants.Color.secondary.withAlphaComponent(0.5)
        tabBar.itemWidth = 80
        tabBar.itemPositioning = .centered
        tabBar.itemSpacing = 2

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
