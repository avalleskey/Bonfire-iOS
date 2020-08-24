//
//  ConversationTableViewCell.swift
//  Bonfire
//
//  Created by James Dale on 21/6/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import BFCore
import Foundation
import UIKit

final class ConversationTableViewCell: UITableViewCell {

    //static let reuseIdentifier = "ConversationTableViewCellReuseIdentifier"

    func updateWithUser(user: User) {
        profileNameLabel.text = String(htmlEncodedString: user.attributes.display_name)
        profileSublineLabel.text = "Start a chat!"

        if let url = user.attributes.media?.avatar?.full?.url {
            profileImageView.backgroundColor = .systemGray
            profileImageView.tintColor = Constants.Color.systemBackground
            profileImageView.kf.setImage(
                with: url,
                placeholder: UIImage(named: "DefaultUserAvatar_light")?.withRenderingMode(
                    .alwaysTemplate),
                options: [
                    .scaleFactor(UIScreen.main.scale),
                    .transition(.fade(1)),
                    .cacheOriginalImage,
                ]
            )
            {
                result in
                switch result {
                case .success(_):
                    self.profileImageView.backgroundColor = .clear
                case .failure(_):
                    break
                }
            }

        } else {
            let campColor = UIColor(hex: user.attributes.color)
            profileImageView.backgroundColor = campColor
            if campColor?.isDarkColor == true {
                profileImageView.image = UIImage(named: "DefaultUserAvatar_light")
            } else {
                profileImageView.image = UIImage(named: "DefaultUserAvatar_dark")
            }
        }
    }

    let profileImageView: UIImageView = {
        let imageView = RoundedImageView()
        imageView.image = UIImage(named: "Austin")!
        return imageView
    }()

    let profileNameLabel: UILabel = {
        let label = UILabel()
        label.text = "Lisandro Matos"
        label.font = UIFont.systemFont(ofSize: 17, weight: .bold).rounded()
        label.textColor = Constants.Color.primary
        return label
    }()

    let profileSublineLabel: UILabel = {
        let label = UILabel()
        label.text = "You: 1 Attachment · 5m"
        label.font = UIFont.systemFont(ofSize: 15, weight: .semibold).rounded()
        label.textColor = Constants.Color.secondary
        return label
    }()

    let profileTextStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        return stackView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
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
            profileImageView.leadingAnchor.constraint(
                equalTo: leadingAnchor,
                constant: 12),
            profileImageView.topAnchor.constraint(
                equalTo: topAnchor,
                constant: 12),
            profileImageView.bottomAnchor.constraint(
                equalTo: bottomAnchor,
                constant: -12),
            profileImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            profileImageView.widthAnchor.constraint(equalTo: profileImageView.heightAnchor),
        ])

        NSLayoutConstraint.activate([
            profileTextStackView.leadingAnchor.constraint(
                equalTo: profileImageView.trailingAnchor,
                constant: 12),
            profileTextStackView.trailingAnchor.constraint(
                equalTo: trailingAnchor,
                constant: -12),
            profileTextStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)

        UIView.animate(
            withDuration: 0.185, delay: 0, options: [.curveEaseOut],
            animations: {
                if highlighted {
                    self.backgroundColor = Constants.Color.cellHighlightedBackground
                } else {
                    self.backgroundColor = nil
                }
            }, completion: nil)
    }

}
