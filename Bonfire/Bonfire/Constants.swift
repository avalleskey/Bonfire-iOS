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
        static let navigationBar: UIColor = {
            if #available(iOS 13.0, *) {
                return UIColor { (traits) -> UIColor in
                    // Return one of two colors depending on light or dark mode
                    return traits.userInterfaceStyle == .dark ?
                        UIColor.systemBackground :
                        UIColor.white
                }
            } else {
                // Same old color used for iOS 12 and earlier
                return UIColor.white
            }
        }()
        
        static let tabBar: UIColor = {
            if #available(iOS 13.0, *) {
                return UIColor { (traits) -> UIColor in
                    // Return one of two colors depending on light or dark mode
                    return traits.userInterfaceStyle == .dark ?
                        UIColor.secondarySystemBackground :
                        UIColor.white
                }
            } else {
                // Same old color used for iOS 12 and earlier
                return UIColor.white
            }
        }()
        
        static let primary: UIColor = {
            if #available(iOS 13.0, *) {
                return UIColor.label
            } else {
                return UIColor.black
            }
        }()
        
        static let secondaryLabel: UIColor = {
            if #available(iOS 13.0, *) {
                return UIColor.secondaryLabel
            } else {
                return UIColor(red: 142/255, green: 142/255, blue: 147/255, alpha: 1)
            }
        }()
        
        static let pillBackground: UIColor = {
            if #available(iOS 13.0, *) {
                return UIColor { (traits) -> UIColor in
                    // Return one of two colors depending on light or dark mode
                    return traits.userInterfaceStyle == .dark ?
                        UIColor.secondarySystemBackground :
                        UIColor.white
                }
            } else {
                // Same old color used for iOS 12 and earlier
                return UIColor.white
            }
        }()
        
        static let bfOrange = UIColor(displayP3Red: 255/255, green: 81/255, blue: 60/255, alpha: 1)
        
        static let textBorder: UIColor = secondaryLabel.withAlphaComponent(0.08)
    }
    
    static let bfAttachmentCornerRadius = 14
}
