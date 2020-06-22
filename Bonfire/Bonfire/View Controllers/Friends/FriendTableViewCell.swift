//
//  FriendTableViewCell.swift
//  Bonfire
//
//  Created by James Dale on 21/6/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation
import UIKit

final class FriendTableViewCell: UITableViewCell {
    
    static let reuseIdentifier = "FriendTableViewCellReuseIdentifier"
    
    let profileImageView: UIImageView = {
        let imageView = RoundedImageView()
        imageView.image = UIImage(named: "Austin")!
        return imageView
    }()
    
    let profileNameLabel: UILabel = {
        let label = UILabel()
        label.text = "Lisandro Matos"
        label.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        label.font = label.font.rounded()
        return label
    }()
    
    let profileSublineLabel: UILabel = {
        let label = UILabel()
        label.text = "You: 1 Attachment · 5m"
        label.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        label.font = label.font.rounded()
        return label
    }()
    
    let profileTextStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        return stackView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureUI() {
        addSubview(profileImageView)
        profileTextStackView.addArrangedSubview(profileNameLabel)
        profileTextStackView.addArrangedSubview(profileSublineLabel)
        addSubview(profileTextStackView)
    }
    
    override func updateConstraints() {
        super.updateConstraints()
        
        
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileTextStackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            profileImageView.leadingAnchor.constraint(equalTo: leadingAnchor,
                                                      constant: 12),
            profileImageView.topAnchor.constraint(equalTo: topAnchor,
                                                  constant: 12),
            profileImageView.bottomAnchor.constraint(equalTo: bottomAnchor,
                                                     constant: -12),
            profileImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            profileImageView.widthAnchor.constraint(equalTo: profileImageView.heightAnchor),
        ])
        
        NSLayoutConstraint.activate([
            profileTextStackView.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor,
                                                          constant: 12),
            profileTextStackView.trailingAnchor.constraint(equalTo: trailingAnchor,
                                                           constant: -12),
            profileTextStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }
    
}
