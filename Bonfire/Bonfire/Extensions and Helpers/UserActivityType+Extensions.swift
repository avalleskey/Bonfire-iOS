//
//  UserActivityType+Extensions.swift
//  Bonfire
//
//  Created by James Dale on 13/8/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import BFCore
import UIKit

extension UserActivityType {
    public typealias Background = (color: UIColor, image: UIImage?)

    public var background: Background {
        switch self {
        case .follow:
            return (
                color: .systemBlue,
                image: UIImage(named: "UserActivity_Follow")
            )
        case .userAcceptedAccess:
            return (
                color: .systemGreen,
                image: UIImage(named: "UserActivity_UserAcceptedAccess")
            )
        case .userPosted:
            return (
                color: .systemOrange,
                image: UIImage(named: "UserActivity_UserPosted")
            )
        case .userPostedCamp:
            return (
                color: .systemOrange,
                image: UIImage(named: "UserActivity_UserPosted")
            )
        case .campAccessRequest:
            return (
                color: .systemGray,
                image: UIImage(named: "UserActivity_CampAccessRequest")
            )
        case .campInvite:
            return (
                color: .systemGreen,
                image: UIImage(named: "UserActivity_CampInvite")
            )
        case .postReply:
            return (
                color: .systemPink,
                image: UIImage(named: "UserActivity_PostReply")
            )
        case .postDefaultReaction:
            return (
                color: .clear,
                image: UIImage(named: "UserActivity_PostReaction_Default")
            )
        default:
            return (
                color: UIColor(white: 0.24, alpha: 1),
                image: UIImage(named: "UserActivity_Misc")
            )
        }
    }
}
