//
//  CampHeaderView.swift
//  Bonfire
//
//  Created by James Dale on 31/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import BFCore
import UIKit
import Cartography

protocol CampHeaderViewDelegate: AnyObject {
    func openCampMembers(camp: Camp)
}

final class CampHeaderView: GenericHeaderView<UIImageView> {
    
    weak var delegate: CampHeaderViewDelegate?
    
    var camp: Camp! {
        didSet {
            // colorize
            color = camp.attributes.uiColor
            
            avatarUrl = camp?.attributes.media?.avatar?.full?.url
            title = camp.attributes.title
            if let camptag = camp.attributes.identifier {
                subtitle = "#\(camptag)"
            } else {
                subtitle = nil
            }
            detail = String(htmlEncodedString: camp.attributes.description ?? "")

            let campStatus: CampStatus = camp.attributes.context?.camp?.status ?? .none

            switch campStatus {
                case .requested:
                    primaryAction.style = .primary(color: color)
                    primaryAction.setTitle("Requested", for: .normal)
                    primaryAction.setImage(UIImage(named: "PlusIcon"), for: .normal)
                case .member:
                    primaryAction.style = .inset(color: color)
                    primaryAction.setTitle("Joined", for: .normal)
                    primaryAction.setImage(UIImage(named: "CheckIcon"), for: .normal)
                case .blocked:
                    primaryAction.style = .inset(color: color)
                    primaryAction.setTitle("Blocked", for: .normal)
                    primaryAction.setImage(UIImage(named: "BlockedIcon"), for: .normal)
                case .invited, .left, .none:
                    primaryAction.style = .inset(color: color)
                    primaryAction.setTitle("Join", for: .normal)
                    primaryAction.setImage(UIImage(named: "PlusIcon"), for: .normal)
                @unknown default:
                    print("unknown campStatus type in CampHeaderView")
                    primaryAction.style = .inset(color: color)
                    primaryAction.setTitle("Join", for: .normal)
                    primaryAction.setImage(UIImage(named: "PlusIcon"), for: .normal)
            }
            
            secondaryAction.setImage(UIImage(named: "CampersIcon"), for: .normal)
            secondaryAction.style = .secondary(color: color)
            if let memberCount = camp.attributes.summaries?.counts?.members {
                secondaryAction.setTitle("\(memberCount)", for: .normal)
            } else {
                secondaryAction.setTitle("Members", for: .normal)
            }
            let isPrivate = camp.attributes.private ?? false
            secondaryAction.isEnabled = (campStatus == .member || !isPrivate)
            
            primaryAction.layoutIfNeeded()
            secondaryAction.layoutIfNeeded()
            
            self.layoutIfNeeded()
        }
    }
    
    override init() {
        super.init()
        
        // place any additional setup here
        secondaryAction.addTarget(self, action: #selector(openCampMembers), for: .touchUpInside)
    }
    
    @objc private func openCampMembers() {
        delegate?.openCampMembers(camp: camp)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
