//
//  AddReplyCell.swift
//  Bonfire
//
//  Created by James Dale on 7/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation
import UIKit

final class AddReplyCell: UITableViewCell, BFPostCell {
    
    static let reuseIdentifier = "AddReplyCellIdentifier"
    
    static let rowHeight: CGFloat = 56

    let profileImageView: UIImageView = {
        let imageView = RoundedImageView()
        imageView.image = UIImage(named: "Austin")!
        return imageView
    }()

    let replyTextField: UITextField = {
        let textField = BFReplyTextField()
        textField.layer.borderColor = Constants.Color.textBorder.cgColor
        textField.layer.borderWidth = 2
        textField.layer.cornerRadius = 22
        textField.placeholder = "Add a reply..."
        textField.font = UIFont.systemFont(ofSize: 16, weight: .semibold).rounded()
        return textField
    }()

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        replyTextField.layer.borderColor = Constants.Color.textBorder.cgColor
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(profileImageView)
        contentView.addSubview(replyTextField)

        updateConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        replyTextField.text = ""
    }

    override func updateConstraints() {
        super.updateConstraints()

        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        replyTextField.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            profileImageView.leadingAnchor.constraint(
                equalTo: leadingAnchor,
                constant: 12),
            profileImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            profileImageView.topAnchor.constraint(
                equalTo: contentView.topAnchor,
                constant: 8),
            profileImageView.bottomAnchor.constraint(
                equalTo: contentView.bottomAnchor,
                constant: -8),

            replyTextField.leadingAnchor.constraint(
                equalTo: profileImageView.trailingAnchor,
                constant: 8),
            replyTextField.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor),
            replyTextField.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
                constant: -12),
        ])
    }

}
