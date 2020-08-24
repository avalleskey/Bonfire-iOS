//
//  PostMessageCell.swift
//  Bonfire
//
//  Created by James Dale on 24/6/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation
import UIKit

final class PostMessageCell: UITableViewCell, BFPostCell {

    //static let reuseIdentifier = "PostMessageCellIdentifier"

    static let rowHeight: CGFloat = UITableView.automaticDimension

    let messageLabel: UILabel = {
        let label = UILabel()
        label.text =
            "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
        label.font = UIFont.systemFont(
            ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize, weight: .semibold)
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
            messageLabel.topAnchor.constraint(
                equalTo: contentView.topAnchor,
                constant: 4),
            messageLabel.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor,
                constant: 12),
            messageLabel.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
                constant: -12),
            contentView.bottomAnchor.constraint(
                equalTo: messageLabel.bottomAnchor,
                constant: 8),
        ])
    }

}
