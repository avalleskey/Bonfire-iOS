//
//  FeedPostCountCell.swift
//  Bonfire
//
//  Created by James Dale on 31/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit

final class FeedPostCountCell: UITableViewCell {
    
    let postCountLabel: UILabel = {
        let label = UILabel()
        label.text = "0 posts"
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        updateConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateConstraints() {
        super.updateConstraints()
        
        postCountLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            postCountLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            postCountLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }
    
}
