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
        static let homeDefaultText = "Activity"
        static let campsDefaultText = "Camps"
        static let friendsDefaultText = "Chats"
        static let notificationsDefaultText = "Notifications"
        static let meDefaultText = "Me"

        static let homeDefaultImage = UIImage(named: "ActivityTabIcon")!
        static let campsDefaultImage = UIImage(named: "CampsTabIcon")!
        static let friendsDefaultImage = UIImage(named: "FriendsTabIcon")!
        static let notificationsDefaultImage = UIImage(named: "NotificationsTabIcon")!
        static let meDefaultImage = UIImage(named: "MeTabIcon")!
    }

    struct Color {
        static let navigationBar: UIColor = {
            if #available(iOS 13.0, *) {
                return UIColor { (traits) -> UIColor in
                    // Return one of two colors depending on light or dark mode
                    return traits.userInterfaceStyle == .dark
                        ? UIColor.systemBackground : UIColor.white
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
                    return traits.userInterfaceStyle == .dark
                        ? UIColor.secondarySystemBackground : UIColor.white
                }
            } else {
                // Same old color used for iOS 12 and earlier
                return UIColor.white
            }
        }()

        static let systemBackground: UIColor = {
            if #available(iOS 13.0, *) {
                return UIColor.systemBackground
            } else {
                return UIColor.white
            }
        }()

        static let groupedBackground: UIColor = {
            if #available(iOS 13.0, *) {
                return UIColor.systemGroupedBackground
            } else {
                return UIColor(red: 0.95, green: 0.95, blue: 0.96, alpha: 1.00)
            }
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

        static let pillBackground: UIColor = {
            if #available(iOS 13.0, *) {
                return UIColor { (traits) -> UIColor in
                    // Return one of two colors depending on light or dark mode
                    return traits.userInterfaceStyle == .dark
                        ? UIColor.secondarySystemBackground : UIColor.white
                }
            } else {
                // Same old color used for iOS 12 and earlier
                return UIColor.white
            }
        }()

        static let brand = UIColor(named: "BrandColor")

        static let secondaryFill: UIColor = {
            let light: UIColor = UIColor(red: 0.97, green: 0.97, blue: 0.98, alpha: 1.00)
            let dark: UIColor = UIColor(red: 0.24, green: 0.25, blue: 0.25, alpha: 1.00)

            return UIColor.dynamicColor(light: light, dark: dark)
        }()

        static let textBorder: UIColor = {
            let light: UIColor = UIColor(white: 0, alpha: 0.08)
            let dark: UIColor = UIColor(white: 1, alpha: 0.16)

            return UIColor.dynamicColor(light: light, dark: dark)
        }()

        static let cellHighlightedBackground: UIColor = {
            let light: UIColor = UIColor(white: 0, alpha: 0.08)
            let dark: UIColor = UIColor(white: 1, alpha: 0.16)

            return UIColor.dynamicColor(light: light, dark: dark)
        }()
    }

    static let bfAttachmentCornerRadius = 14
}
