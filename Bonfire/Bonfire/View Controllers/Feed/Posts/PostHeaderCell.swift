//
//  PostHeaderView.swift
//  Bonfire
//
//  Created by James Dale on 22/6/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation
import UIKit

protocol PostHeaderCellDelegate: class {
    func profileBtnTap(cell: UITableViewCell)
}

final class PostHeaderCell: UITableViewCell, BFPostCell {

    static let reuseIdentifier = "PostHeaderCellIdentifier"

    static let rowHeight: CGFloat = 64
    
    weak var delegate: PostHeaderCellDelegate?

    enum Style {
        case profile
        case camp
    }

    var headerStyle: Style = .camp {
        didSet {
            campLabel.isHidden = headerStyle != .camp
        }
    }

    let profileImageView: BFCircularButton = {
        let imageView = BFCircularButton()
        imageView.setImage(UIImage(named: "Austin")!, for: .normal)
        return imageView
    }()

    let profileLabel: UILabel = {
        let label = UILabel()
        label.text = "@hugo"
        label.textColor = Constants.Color.primary
        label.font = UIFont.systemFont(ofSize: 16, weight: .bold).rounded()
        return label
    }()

    let campLabel: UILabel = {
        let label = UILabel()
        label.text = "in YEETVILLE"
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold).rounded()
        label.textColor = Constants.Color.secondary
        return label
    }()

    let headerLabelStack: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        return stackView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        headerLabelStack.addArrangedSubview(profileLabel)
        headerLabelStack.addArrangedSubview(campLabel)

        contentView.addSubview(profileImageView)
        contentView.addSubview(headerLabelStack)
        
        isUserInteractionEnabled = true

        updateConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateConstraints() {
        super.updateConstraints()

        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        headerLabelStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            profileImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            profileImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            profileImageView.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            headerLabelStack.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor),
            headerLabelStack.leadingAnchor.constraint(
                equalTo: profileImageView.trailingAnchor,
                constant: 12),
        ])
    }
    
    override func prepareForReuse() {
        profileImageView.removeTarget(self, action: #selector(profileImageTap), for: .touchUpInside)
    }
    
    @objc func profileImageTap(sender: UIButton) {
        delegate?.profileBtnTap(cell: self)
    }

}
