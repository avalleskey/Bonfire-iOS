//
//  PostActionView.swift
//  Bonfire
//
//  Created by James Dale on 22/6/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation
import UIKit

final class PostActionsCell: UITableViewCell {
    
    static let reuseIdentifier = "PostActionsCellIdentifier"
    
    let repliesBtn: UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage(named: "ReplyThreshold0"), for: .normal)
        btn.setTitle("11 notes", for: .normal)
        btn.setTitleColor(Constants.Color.label, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        btn.titleLabel?.font = btn.titleLabel?.font.rounded()
        btn.titleEdgeInsets = .init(top: 0, left: 13, bottom: 0, right: -13)
        btn.contentMode = .center
        return btn
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(repliesBtn)
        
        updateConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateConstraints() {
        super.updateConstraints()
        
        repliesBtn.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            repliesBtn.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,
                                                constant: 17),
            repliesBtn.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
}
