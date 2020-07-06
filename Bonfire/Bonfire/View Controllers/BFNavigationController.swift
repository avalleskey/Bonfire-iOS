//
//  BFNavigationController.swift
//  Bonfire
//
//  Created by James Dale on 22/6/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation
import UIKit
import Hero

final class BFNavigationController: UINavigationController {
    
    private let bfNavigationItem: UINavigationItem = {
        let item = UINavigationItem()
        let profileImage = RoundedImageView(image: UIImage(named: "Austin"))
        profileImage.heightAnchor.constraint(equalToConstant: 34).isActive = true
        profileImage.widthAnchor.constraint(equalToConstant: 34).isActive = true
        item.leftBarButtonItem = .init(customView: profileImage)
        item.rightBarButtonItem = .init(barButtonSystemItem: .bookmarks,
                                                                 target: self,
                                                                 action: nil)
        return item
    }()
    
    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        delegate = self
        hero.isEnabled = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension BFNavigationController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        
        viewController.navigationItem.leftBarButtonItem = bfNavigationItem.leftBarButtonItem
        viewController.navigationItem.rightBarButtonItem = bfNavigationItem.rightBarButtonItem
        
        switch viewController {
        case is HomeViewController:
            let icon = UIImage(named: "HomeNavIcon")
            viewController.navigationItem.rightBarButtonItem = .init(image: icon,
                                                                     style: .plain,
                                                                     target: nil,
                                                                     action: nil)
            viewController.navigationItem.rightBarButtonItem?.tintColor = .black
        case is FriendsViewController:
            let icon = UIImage(named: "FriendsNavIcon")
            viewController.navigationItem.rightBarButtonItem = .init(image: icon,
                                                                     style: .plain,
                                                                     target: nil,
                                                                     action: nil)
            viewController.navigationItem.rightBarButtonItem?.tintColor = .black
            
        case is CampsViewController:
            let icon = UIImage(named: "MoreNavIcon")
            viewController.navigationItem.rightBarButtonItem = .init(image: icon,
                                                                     style: .plain,
                                                                     target: nil,
                                                                     action: nil)
            viewController.navigationItem.rightBarButtonItem?.tintColor = .black
        default:
            break
        }
    }
}
