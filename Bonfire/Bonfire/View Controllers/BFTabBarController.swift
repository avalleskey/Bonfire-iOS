//
//  BFTabBarController.swift
//  Bonfire
//
//  Created by James Dale on 21/6/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit
import Hero

final class BFTabBarController: UITabBarController {
    
    override var selectedViewController: UIViewController? {
        didSet {
            if oldValue == selectedViewController && selectedViewController?.tabBarItem.tag == 1 {
                present(CreatePostViewController(), animated: true)
            } else if oldValue?.tabBarItem.tag == 1 {
                oldValue?.tabBarItem.title = "Home"
            }
            else if selectedViewController?.tabBarItem.tag == 1 {
                selectedViewController?.tabBarItem.title = ""
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tabBar.tintColor = Constants.Color.primary
        tabBar.backgroundColor = Constants.Color.tabBar
        tabBar.isTranslucent = false
        tabBar.backgroundImage = UIImage()
        tabBar.shadowImage = UIImage(named: "TabBarShadow")
        
        let tabBarItemFont = UIFont.systemFont(ofSize: 12, weight: .bold).rounded()
        let appearance = UITabBarItem.appearance()
        let attributes = [NSAttributedString.Key.font:tabBarItemFont]
        appearance.setTitleTextAttributes(attributes, for: .normal)
        appearance.titlePositionAdjustment = .init(horizontal: 0, vertical: -5)
        
        updateViewConstraints()
        hero.isEnabled = false
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

}
