//
//  PostImageAttachmentCell.swift
//  Bonfire
//
//  Created by James Dale on 5/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit

final class PostImageAttachmentCell: UITableViewCell {
    
    let attachmentImageView: UIImageView = {
        return UIImageView()
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(attachmentImageView)
        
        updateConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateConstraints() {
        super.updateConstraints()
        
        attachmentImageView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            attachmentImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            attachmentImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            attachmentImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,
                                                         constant: 12),
            attachmentImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                                          constant: -12),
        ])
    }
    
    
}
