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
    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
        
        pills.forEach {
            let pill = $0
            if pill.tag == item.tag {
                UIView.animate(withDuration: 0.6, delay: 0.15, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: [.curveEaseInOut], animations: {
                    pill.transform = CGAffineTransform.identity.scaledBy(x: 1, y: 1)
                    pill.center = CGPoint(x: self.view.frame.size.width / 2, y: tabBar.frame.origin.y - pill.frame.size.height/2 - 16)
                }, completion: nil)
            }
            else if pill.alpha == 1 {
                UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: [.curveEaseInOut], animations: {
                    pill.center = CGPoint(x: self.view.frame.size.width / 2, y: tabBar.frame.origin.y + tabBar.frame.size.height / 2)
                    pill.transform = CGAffineTransform.identity.scaledBy(x: 0.6, y: 0.6)
                }, completion: nil)
            }
        }
    }
    
    private var pills = [BFPillButton]()

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

    func addPillButton(_ pillButton: BFPillButton, viewController: UIViewController) {
        pills.append(pillButton)
        view.insertSubview(pillButton, belowSubview: tabBar)
        
        pillButton.transform = CGAffineTransform.identity.scaledBy(x: 0.6, y: 0.6)
        pillButton.center = CGPoint(x: view.frame.size.width / 2, y: tabBar.frame.origin.y + tabBar.frame.size.height / 2)
    }
    
    @objc func addCamps() {
        print("add camps")
    }
}
