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
                selectedViewController?.tabBarItem.title = "Home"
            }
            
            if selectedViewController?.tabBarItem.tag == 1 {
                selectedViewController?.tabBarItem.title = ""
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tabBar.round(corners: [.layerMinXMinYCorner, .layerMaxXMinYCorner], radius: 28)
        tabBar.clipsToBounds = true
        tabBar.tintColor = .black
        
        updateViewConstraints()
        hero.isEnabled = true
        
        delegate = self
    }
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        
        tabBar.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }

}

// MARK: - UITabBarControllerDelegate
extension BFTabBarController: UITabBarControllerDelegate {
    
}
