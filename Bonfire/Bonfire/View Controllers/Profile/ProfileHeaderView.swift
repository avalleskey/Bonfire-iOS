//
//  ProfileHeaderView.swift
//  Bonfire
//
//  Created by James Dale on 31/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import BFCore
import UIKit
import Cartography

final class ProfileHeaderView: GenericHeaderView<UIImageView> {
    var user: User! {
        didSet {
            // colorize
            color = user.attributes.uiColor
            
            avatarUrl = user?.attributes.media?.avatar?.full?.url
            title = user.attributes.displayName
            subtitle = "@\(user.attributes.identifier)"
            detail = String(htmlEncodedString: user.attributes.bio ?? "")

            let userStatus: UserStatus = user.attributes.context?.me?.status ?? .noRelation
            
            switch userStatus {
                case .me:
                    primaryAction.style = .secondary(color: color)
                    primaryAction.setTitle("Settings", for: .normal)
                    primaryAction.setImage(UIImage(named: "SettingsIcon"), for: .normal)
                    secondaryAction.isHidden = true
                case .noRelation, .followed:
                    primaryAction.style = .primary(color: color)
                    primaryAction.setTitle((userStatus == UserStatus.followed ? "Add Back" : "Add Friend"), for: .normal)
                    primaryAction.setImage(UIImage(named: "PlusIcon"), for: .normal)
                    secondaryAction.isHidden = false
                case .follows:
                    primaryAction.style = .inset(color: color)
                    primaryAction.setTitle("Following", for: .normal)
                    primaryAction.setImage(UIImage(named: "CheckIcon"), for: .normal)
                    secondaryAction.isHidden = false
                case .followsBoth:
                    primaryAction.style = .inset(color: color)
                    primaryAction.setTitle("Friends", for: .normal)
                    primaryAction.setImage(UIImage(named: "CheckIcon"), for: .normal)
                    secondaryAction.isHidden = false
                case .blocks, .blocked, .blocksBoth:
                    primaryAction.style = .inset(color: color)
                    primaryAction.setTitle("Blocked", for: .normal)
                    primaryAction.setImage(UIImage(named: "BlockedIcon"), for: .normal)
                    secondaryAction.isHidden = true
                @unknown default:
                    break
            }
            secondaryAction.style = .secondary(color: color)
            
            primaryAction.layoutIfNeeded()
            secondaryAction.layoutIfNeeded()
        }
    }
    
    override init() {
        super.init()
        
        // place any additional setup here
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
