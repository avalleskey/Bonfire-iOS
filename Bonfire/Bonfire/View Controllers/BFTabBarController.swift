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

    let composeButton: UIButton = {
        let button = BFBouncyButton()
        button.setImage(
            UIImage(named: "CreatePost"), for: .normal)
        button.frame = CGRect(
            x: 0, y: 0, width: (UIScreen.main.bounds.size.width - 24) / 3, height: 46)
        button.layer.cornerRadius = button.frame.size.height / 2
        button.backgroundColor = Constants.Color.secondary.withAlphaComponent(0.08)
        button.layer.cornerRadius = 23
        button.tintColor = Constants.Color.primary
        button.imageEdgeInsets = .init(top: -2, left: 0, bottom: 0, right: -2)
        button.addTarget(self, action: #selector(compose), for: .touchUpInside)
        return button
    }()

    override var selectedViewController: UIViewController? {
        didSet {
            if oldValue == selectedViewController {
                // scroll to top
                selectedViewController!.scrollToTop()
            } else if oldValue?.tabBarItem.tag == 1 {
                tabBar.tintColor = Constants.Color.primary

                hideCompose()
            } else if selectedViewController?.tabBarItem.tag == 1 {
                tabBar.tintColor = Constants.Color.secondary

                showCompose()
            }
        }
    }

    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        //        let generator = UISelectionFeedbackGenerator()
        //        generator.selectionChanged()
        //
        //        showPillIfNeeded(item: item)
    }

    private var pills = [BFPillButton]()

    override func viewDidLoad() {
        super.viewDidLoad()

        composeButton.center = CGPoint(
            x: tabBar.frame.size.width / 2,
            y: tabBar.frame.origin.y - 44 + (tabBar.frame.size.height / 2) + 5)
        view.insertSubview(composeButton, aboveSubview: tabBar)

        tabBar.backgroundColor = Constants.Color.tabBar
        tabBar.isTranslucent = false
        tabBar.backgroundImage = UIImage()
        tabBar.shadowImage = UIImage(named: "TabBarShadow")
        tabBar.tintColor = Constants.Color.primary
        tabBar.unselectedItemTintColor = Constants.Color.secondary

        let tabBarItemFont = UIFont.systemFont(ofSize: 12, weight: .bold).rounded()
        let appearance = UITabBarItem.appearance()
        let attributes = [NSAttributedString.Key.font: tabBarItemFont]
        appearance.setTitleTextAttributes(attributes, for: .normal)
        appearance.titlePositionAdjustment = .init(horizontal: 0, vertical: -5)

        updateViewConstraints()
        hero.isEnabled = false

        delegate = self
    }

    override func updateViewConstraints() {
        super.updateViewConstraints()

        tabBar.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }

    override func viewDidLayoutSubviews() {
        super.viewWillLayoutSubviews()
        tabBar.frame.size.height = 92
        tabBar.frame.origin.y = view.frame.height - 92
    }

    private func showPillIfNeeded(item: UITabBarItem) {
        pills.forEach {
            let pill = $0
            if pill.tag == item.tag {
                UIView.animate(
                    withDuration: 0.6, delay: 0.15, usingSpringWithDamping: 0.7,
                    initialSpringVelocity: 0.5, options: [.curveEaseInOut],
                    animations: {
                        pill.transform = CGAffineTransform.identity.scaledBy(x: 1, y: 1)
                        pill.center = CGPoint(
                            x: self.view.frame.size.width / 2,
                            y: self.tabBar.frame.origin.y - pill.frame.size.height / 2 - 16)
                    }, completion: nil)
            } else if pill.alpha == 1 {
                UIView.animate(
                    withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.8,
                    initialSpringVelocity: 0.5, options: [.curveEaseInOut],
                    animations: {
                        pill.center = CGPoint(
                            x: self.view.frame.size.width / 2,
                            y: self.tabBar.frame.origin.y + self.tabBar.frame.size.height / 2)
                        pill.transform = CGAffineTransform.identity.scaledBy(x: 0.6, y: 0.6)
                    }, completion: nil)
            }
        }
    }

    func hideCompose() {
        let homeTabItemView: UIView = viewForTab(index: 1)

        UIView.animate(
            withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5,
            options: [.curveEaseInOut],
            animations: {
                self.composeButton.transform = CGAffineTransform.identity.scaledBy(x: 0.4, y: 0.6)
                self.composeButton.alpha = 0
            }, completion: nil)

        UIView.animate(
            withDuration: 0.3, delay: 0.2, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5,
            options: [.curveEaseInOut],
            animations: {
                homeTabItemView.alpha = 1
                homeTabItemView.transform = CGAffineTransform.init(translationX: 0, y: 0)
            }, completion: nil)
    }
    func showCompose() {
        let homeTabItemView: UIView = self.viewForTab(index: 1)

        UIView.animate(
            withDuration: 0.4, delay: 0.1, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5,
            options: [.curveEaseInOut],
            animations: {
                self.composeButton.transform = CGAffineTransform.identity.scaledBy(x: 1, y: 1)
                self.composeButton.alpha = 1
            }, completion: nil)

        UIView.animate(
            withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5,
            options: [.curveEaseInOut],
            animations: {
                homeTabItemView.alpha = 0
            },
            completion: { finished in
                homeTabItemView.transform = CGAffineTransform.init(translationX: 0, y: 6)
            })
    }

    func addPillButton(_ pillButton: BFPillButton, viewController: UIViewController) {
        pills.append(pillButton)
        view.insertSubview(pillButton, belowSubview: tabBar)

        pillButton.transform = CGAffineTransform.identity.scaledBy(x: 0.6, y: 0.6)
        pillButton.center = CGPoint(
            x: view.frame.size.width / 2, y: tabBar.frame.origin.y + tabBar.frame.size.height / 2)
    }

    @objc func addFriends() {
        let items: [Any] = [
            "Add me on Bonfire! 🔥", URL(string: "https://www.bonfire.camp/u/austin")!,
        ]
        let ac = UIActivityViewController(activityItems: items, applicationActivities: nil)
        present(ac, animated: true)
    }
    @objc func addCamps() {
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

    func viewForTab(index: NSInteger) -> UIView {
        var allItems = [UIView]()
        for tabBarItem in tabBar.subviews {
            if tabBarItem.isKind(of: NSClassFromString("UITabBarButton")!) {
                allItems.append(tabBarItem)
            }
        }
        return allItems[index]
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
    func tabBarController(
        _ tabBarController: UITabBarController, didSelect viewController: UIViewController
    ) {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()

        showPillIfNeeded(item: viewController.tabBarItem)
    }
}
