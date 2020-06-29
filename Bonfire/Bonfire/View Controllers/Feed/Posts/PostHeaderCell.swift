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
    
    let profileImageView: UIImageView = {
        let imageView = RoundedImageView()
        imageView.image = UIImage(named: "Austin")!
        return imageView
    }()
    
    let profileLabel: UILabel = {
        let label = UILabel()
        label.text = "@hugo"
        label.textColor = .systemBlue
        label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        label.font = label.font.rounded()
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(profileImageView)
        contentView.addSubview(profileLabel)
        
        updateConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateConstraints() {
        super.updateConstraints()
        
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            profileImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            profileImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            profileImageView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            profileLabel.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor),
            profileLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor,
                                                  constant: 8)
        ])
    }
    
    
}
