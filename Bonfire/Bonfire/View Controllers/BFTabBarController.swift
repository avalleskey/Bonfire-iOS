//
//  BFTabBarController.swift
//  Bonfire
//
//  Created by James Dale on 21/6/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit

class BFTabBarController: UITabBarController {
    
    override var selectedViewController: UIViewController? {
        didSet {
            if oldValue == selectedViewController && selectedViewController?.tabBarItem.tag == 1 {
                present(CreatePostViewController(), animated: true)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tabBar.round(corners: [.layerMinXMinYCorner, .layerMaxXMinYCorner], radius: 28)
        tabBar.clipsToBounds = true
        
        updateViewConstraints()
        
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
