//
//  Constants.swift
//  Bonfire
//
//  Created by James Dale on 20/6/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation
import UIKit

struct Constants {
    struct TabBar {
        static let homeDefaultText = "Home"
        static let campsDefaultText = "Camps"
        static let friendsDefaultText = "Friends"
        
        static let homeDefaultImage = UIImage(named: "Home")!
        static let campsDefaultImage = UIImage(named: "Camps")!
        static let friendsDefaultImage = UIImage(named: "Friends")!
        
        static let createPostImage = UIImage(named: "CreatePost")!
    }
    
    struct Color {
        static let label: UIColor = {
            if #available(iOS 13.0, *) {
                return UIColor.label
            } else {
                return UIColor.black
            }
        }()
        
        static let bfOrange = UIColor(red: 255/255, green: 81/255, blue: 60/255, alpha: 1)
        
        static let textBorder: UIColor = .init(red: 225/255,
                                               green: 227/255,
                                               blue: 230/255,
                                               alpha: 0.3)
    }
    
    static let bfAttachmentCornerRadius = 14
}
