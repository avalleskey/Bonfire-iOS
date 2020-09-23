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
        static let messagesDefaultText = "Messages"
        static let notificationsDefaultText = "Notifications"

        static let homeDefaultImage = UIImage(named: "HomeTabIcon")!
        static let campsDefaultImage = UIImage(named: "CampsTabIcon")!
        static let composeDefaultImage = UIImage(named: "ComposeTabIcon")!
        static let friendsDefaultImage = UIImage(named: "FriendsTabIcon")!
        static let notificationsDefaultImage = UIImage(named: "NotificationsTabIcon")!
    }

    struct Color {
        static let navigationBar: UIColor = {
            return systemBackground
        }()

        static let tabBar: UIColor = {
            let light: UIColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1.00).withAlphaComponent(0.8)
            let dark: UIColor = UIColor(red: 0.08, green: 0.08, blue: 0.1, alpha: 1.00).withAlphaComponent(0.7)

            return UIColor.dynamicColor(light: light, dark: dark)
        }()
        static let tabBarSeparator: UIColor = {
            let light: UIColor = UIColor(white: 0, alpha: 0.12)
            let dark: UIColor = UIColor(white: 1, alpha: 0)

            return UIColor.dynamicColor(light: light, dark: dark)
        }()

        static let systemBackground: UIColor = {
            if #available(iOS 13.0, *) {
                return UIColor.systemBackground
            } else {
                return UIColor.white
            }
        }()

        static let groupedBackground: UIColor = {
            let light: UIColor = UIColor(red: 0.95, green: 0.95, blue: 0.96, alpha: 1.00)
            let dark: UIColor = UIColor(red: 0.02, green: 0.02, blue: 0.03, alpha: 1.00)

            return UIColor.dynamicColor(light: light, dark: dark)
        }()

        static let primary: UIColor = {
            if #available(iOS 13.0, *) {
                return UIColor.label
            } else {
                return UIColor.black
            }
        }()

        static let secondary: UIColor = {
            if #available(iOS 13.0, *) {
                return UIColor.secondaryLabel
            } else {
                return UIColor(red: 142 / 255, green: 142 / 255, blue: 147 / 255, alpha: 1)
            }
        }()
        
        static let gray2: UIColor = {
            if #available(iOS 13, *) {
                return UIColor.systemGray2
            }
            return UIColor(red: 99 / 255, green: 99 / 255, blue: 102 / 255, alpha: 1)
        }()

        static let postBackground: UIColor = {
            let light: UIColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1.00)
            let dark: UIColor = UIColor(red: 0.06, green: 0.06, blue: 0.08, alpha: 1.00)

            return UIColor.dynamicColor(light: light, dark: dark)
        }()

        static let brand = UIColor(named: "BrandColor")!

        static let secondaryFill: UIColor = {
            let light: UIColor = UIColor(red: 0.97, green: 0.97, blue: 0.98, alpha: 1.00)
            let dark: UIColor = UIColor(red: 0.24, green: 0.25, blue: 0.25, alpha: 1.00)

            return UIColor.dynamicColor(light: light, dark: dark)
        }()

        static let borderColor: UIColor = {
            let light: UIColor = UIColor(white: 0, alpha: 0.08)
            let dark: UIColor = UIColor(white: 1, alpha: 0.16)

            return UIColor.dynamicColor(light: light, dark: dark)
        }()
        
        static let separatorColor: UIColor = {
            let light: UIColor = UIColor(red: 238 / 255, green: 238 / 255, blue: 240 / 255, alpha: 1)
            let dark: UIColor = UIColor(red: 51 / 255, green: 51 / 255, blue: 56 / 255, alpha: 1)

            return UIColor.dynamicColor(light: light, dark: dark)
        }()

        static let cellHighlightedBackground: UIColor = {
            let light: UIColor = UIColor(white: 0, alpha: 0.06)
            let dark: UIColor = UIColor(white: 1, alpha: 0.08)

            return UIColor.dynamicColor(light: light, dark: dark)
        }()
        
        static let textFieldBackground: UIColor = {
            let light: UIColor = UIColor(red: 240 / 255, green: 240 / 255, blue: 242 / 255, alpha: 1)
            let dark: UIColor = UIColor(red: 12 / 255, green: 12 / 255, blue: 14 / 255, alpha: 1)

            return UIColor.dynamicColor(light: light, dark: dark)
        }()
        
        static let shadedButtonBackgroundColor: UIColor = {
            let light: UIColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.03)
            let dark: UIColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.12)

            return UIColor.dynamicColor(light: light, dark: dark)
        }()
    }

    static let bfAttachmentCornerRadius = 14
}
