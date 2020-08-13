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

    static let rowHeight: CGFloat = 50

    weak var delegate: PostHeaderCellDelegate?

    enum Style {
        case fire
        case live
        case statusUpdate
        case mention
        case friendSuggestion
    }

    var headerStyle: Style = .fire {
        didSet {

        }
    }

    let profileImageView: BFCircularButton = {
        let imageView = BFCircularButton()
        imageView.setImage(UIImage(named: "Austin")!, for: .normal)
        return imageView
    }()

    let primaryLabel: UILabel = {
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

    let headerStack: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        return stackView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        headerStack.addArrangedSubview(profileImageView)
        headerStack.addArrangedSubview(primaryLabel)

        contentView.addSubview(headerStack)

        isUserInteractionEnabled = true

        updateConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateConstraints() {
        super.updateConstraints()

        headerStack.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            headerStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            headerStack.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            headerStack.heightAnchor.constraint(equalToConstant: 24),
            
            profileImageView.widthAnchor.constraint(equalTo: headerStack.heightAnchor),
            profileImageView.heightAnchor.constraint(equalTo: profileImageView.widthAnchor),
        ])
    }

    override func prepareForReuse() {
        profileImageView.removeTarget(self, action: #selector(profileImageTap), for: .touchUpInside)
    }

    @objc func profileImageTap(sender: UIButton) {
        delegate?.profileBtnTap(cell: self)
    }

}
