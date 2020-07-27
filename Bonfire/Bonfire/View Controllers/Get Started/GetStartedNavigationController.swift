//
//  GetStartedNavigationController.swift
//  Bonfire
//
//  Created by James Dale on 24/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

// TODO: We definitely need a better name for this.

import UIKit

final class GetStartedNavigationController: UINavigationController {
    
    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        
        navigationBar.isTranslucent = true
        navigationBar.backgroundColor = .clear
        view.backgroundColor = .clear
        navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationBar.shadowImage = UIImage()
        delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        
        NSLayoutConstraint.activate([
            navigationBar.heightAnchor.constraint(equalToConstant: 76)
        ])
    }
}

extension GetStartedNavigationController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        let backImage = UIImage(named: "LeftNavIcon")
        navigationBar.backIndicatorImage = backImage
        navigationBar.backIndicatorTransitionMaskImage = backImage
    }
    
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        navigationBar.backItem?.title = ""
    }
}
