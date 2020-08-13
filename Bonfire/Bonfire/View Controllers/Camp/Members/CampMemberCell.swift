//
//  CampMemberCell.swift
//  Bonfire
//
//  Created by James Dale on 31/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit

final class CampMemberCell: UITableViewCell {

    let profileImageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()

    let primaryLabel: UILabel = {
        let label = UILabel()
        label.text = "John Smith"
        label.font = UIFont.systemFont(ofSize: 17, weight: .bold).rounded()
        label.textColor = Constants.Color.primary
        return label
    }()

    let secondaryLabel: UILabel = {
        let label = UILabel()
        label.text = "Joined 2d ago"
        label.font = UIFont.systemFont(ofSize: 15, weight: .bold).rounded()
        label.textColor = Constants.Color.secondary
        return label
    }()

    let stackView = UIStackView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        addSubview(profileImageView)
        addSubview(stackView)

        stackView.addArrangedSubview(primaryLabel)
        stackView.addArrangedSubview(secondaryLabel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateConstraints() {
        super.updateConstraints()

        profileImageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            profileImageView.leadingAnchor.constraint(
                equalTo: leadingAnchor,
                constant: 12),

            stackView.leadingAnchor.constraint(
                equalTo: profileImageView.trailingAnchor,
                constant: 12),
        ])
    }
}
