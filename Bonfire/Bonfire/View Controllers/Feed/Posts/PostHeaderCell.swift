//
//  PostHeaderView.swift
//  Bonfire
//
//  Created by James Dale on 22/6/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation
import UIKit

final class PostHeaderCell: UITableViewCell {
    static let reuseIdentifier = "PostHeaderCellIdentifier"
    
    let profileLabel: UILabel = {
        let label = UILabel()
        label.text = "@hugo"
        label.textColor = Constants.Color.label
        label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        label.font = label.font.rounded()
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(profileLabel)
        
        updateConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateConstraints() {
        super.updateConstraints()
        
        profileLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            profileLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            profileLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,
                                                  constant: 12)
        ])
    }
    
    
}
