//
//  BFTabBarController.swift
//  Bonfire
//
//  Created by James Dale on 21/6/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit
import Hero
import SwipeableTabBarController

final class BFTabBarController: SwipeableTabBarController {
    
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

        tabBar.clipsToBounds = true
        tabBar.tintColor = .black
        tabBar.backgroundColor = .white
        tabBar.layer.shadowColor = UIColor.black.cgColor
        tabBar.layer.shadowOpacity = 0.16
        tabBar.layer.shadowOffset = .init(width: 0, height: -1)
        tabBar.layer.shadowRadius = 6
        
        updateViewConstraints()
        hero.isEnabled = true
        
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

}
