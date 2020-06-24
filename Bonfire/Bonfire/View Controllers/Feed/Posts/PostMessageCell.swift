//
//  PostMessageCell.swift
//  Bonfire
//
//  Created by James Dale on 24/6/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation
import UIKit

final class PostMessageCell: UITableViewCell {
    
    static let reuseIdentifier = "PostMessageCellIdentifier"
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.text = "hey hey hey, who else loves Bonfire 2.0!?"
        label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        label.font = label.font.rounded()
        label.numberOfLines = 0
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(messageLabel)
        updateConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateConstraints() {
        super.updateConstraints()
        
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            messageLabel.topAnchor.constraint(equalTo: contentView.topAnchor,
                                              constant: 10),
            messageLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,
                                                  constant: 12),
            messageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                                  constant: -12),
        ])
    }
    
}
