//
//  AppLink.swift
//  Bonfire
//
//  Created by James Dale on 20/8/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import BFCore
import Foundation
import UIKit

enum AppLink {
    case post(String)
    case profile(String)
    case camp(String)
    case compose
    case settings
    case search
    
    var viewController: UIViewController {
        switch self {
        case .post(let postId):
            let vc = UIViewController()
            return vc
        case .profile(let profileId):
            let vc = ProfileViewController()
            vc.load(id: profileId)
            return vc
        case .camp(let campId):
//            let vc = CampViewController(camp: nil)
            return TestViewController()
        case .compose:
            let vc = CreatePostViewController()
            return vc
        case .settings:
            let vc = SettingsViewController()
            return vc
        case .search:
            let vc = UIViewController()
            return vc
        }
    }
    
    static func from(url: URL) -> Self? {
        let action = url.pathComponents.last
        switch action {
        case "post":
            return .post("")
        case "profile":
            return .profile("")
        case "camp":
            return .camp("")
        default:
            return nil
        }
    }
}
