//
//  NotificationTableViewCell.swift
//  Bonfire
//
//  Created by Austin Valleskey on 24/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import BFCore
import Foundation
import UIKit

final class NotificationTableViewCell: UITableViewCell {

    static let reuseIdentifier = "NotificationTableViewCellReuseIdentifier"

    var type: UserActivityType = .unknown {
        didSet {
            var typeImage: UIImage? = nil
            switch type {
            case .follow:
                typeImageView.backgroundColor = .systemBlue
                typeImage = UIImage(named: "UserActivity_Follow")
            case .userAcceptedAccess:
                typeImageView.backgroundColor = .systemGreen
                typeImage = UIImage(named: "UserActivity_UserAcceptedAccess")
            case .userPosted:
                typeImageView.backgroundColor = .systemOrange
                typeImage = UIImage(named: "UserActivity_UserPosted")
            case .userPostedCamp:
                typeImageView.backgroundColor = .systemOrange
                typeImage = UIImage(named: "UserActivity_UserPosted")
            case .campAccessRequest:
                typeImageView.backgroundColor = .systemGray
                typeImage = UIImage(named: "UserActivity_CampAccessRequest")
            case .campInvite:
                typeImageView.backgroundColor = .systemGreen
                typeImage = UIImage(named: "UserActivity_CampInvite")
            case .postReply:
                typeImageView.backgroundColor = .systemPink
                typeImage = UIImage(named: "UserActivity_PostReply")
            case .postDefaultReaction:
                typeImageView.backgroundColor = .clear
                typeImage = UIImage(named: "UserActivity_PostReaction_Default")

            default:
                typeImageView.backgroundColor = UIColor(white: 0.24, alpha: 1)
                typeImage = UIImage(named: "UserActivity_Misc")
            }

            if typeImage != nil {
                typeImageView.image = typeImage
            }
        }
    }

    var read: Bool = false {
        didSet {
            unreadDotView.isHidden = read
        }
    }

    let profileImageView: UIImageView = {
        let imageView = RoundedImageView()
        imageView.image = UIImage(named: "Austin")!
        return imageView
    }()

    let typeImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.tintColor = .white
        imageView.layer.cornerRadius = 11
        imageView.layer.shadowOffset = CGSize(width: 0, height: 1)
        imageView.layer.shadowRadius = 3
        imageView.layer.shadowColor = UIColor.black.cgColor
        imageView.layer.shadowOpacity = 0.16
        return imageView
    }()

    let unreadDotView: UIView = {
        let view = RoundedView()
        view.backgroundColor = .systemBlue
        return view
    }()

    let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Abayo Stevens reacted to your post"
        label.font = UIFont.systemFont(ofSize: 17, weight: .bold).rounded()
        label.textColor = Constants.Color.primary
        label.numberOfLines = 0
        return label
    }()

    let dateLabel: UILabel = {
        let label = UILabel()
        label.text = "2h ago"
        label.font = UIFont.systemFont(ofSize: 15, weight: .semibold).rounded()
        label.textColor = Constants.Color.secondary
        return label
    }()

    let textStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 2
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
        contentView.addSubview(profileImageView)
        contentView.addSubview(typeImageView)
        contentView.addSubview(unreadDotView)

        textStackView.addArrangedSubview(titleLabel)
        textStackView.addArrangedSubview(dateLabel)
        contentView.addSubview(textStackView)

        updateConstraints()
    }

    override func updateConstraints() {
        super.updateConstraints()

        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        typeImageView.translatesAutoresizingMaskIntoConstraints = false
        unreadDotView.translatesAutoresizingMaskIntoConstraints = false
        textStackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            profileImageView.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor,
                constant: 12),
            profileImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            profileImageView.widthAnchor.constraint(equalToConstant: 48),
            profileImageView.heightAnchor.constraint(equalTo: profileImageView.widthAnchor),

            textStackView.leadingAnchor.constraint(
                equalTo: profileImageView.trailingAnchor,
                constant: 12),
            textStackView.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
                constant: -12),
            textStackView.topAnchor.constraint(equalTo: profileImageView.topAnchor),

            typeImageView.trailingAnchor.constraint(
                equalTo: profileImageView.trailingAnchor),
            typeImageView.bottomAnchor.constraint(
                equalTo: profileImageView.bottomAnchor),
            typeImageView.widthAnchor.constraint(equalToConstant: 24),
            typeImageView.heightAnchor.constraint(equalTo: typeImageView.widthAnchor),

            unreadDotView.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor,
                constant: 3),
            unreadDotView.centerYAnchor.constraint(
                equalTo: profileImageView.centerYAnchor),
            unreadDotView.widthAnchor.constraint(equalToConstant: 6),
            unreadDotView.heightAnchor.constraint(equalTo: unreadDotView.widthAnchor),

            contentView.bottomAnchor.constraint(
                greaterThanOrEqualTo: textStackView.bottomAnchor,
                constant: 12),
            contentView.heightAnchor.constraint(
                greaterThanOrEqualTo: profileImageView.heightAnchor, multiplier: 1, constant: 24),
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

extension NSAttributedString {
    static func entityString(string: String, entities: [BFEntity]?) -> NSAttributedString {
        let font: UIFont = UIFont.systemFont(ofSize: 17, weight: .medium)

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font.rounded(),
            .foregroundColor: Constants.Color.primary,
        ]
        let mutableAttributedString = NSMutableAttributedString(
            string: string, attributes: attributes)

        if entities != nil {
            entities?.forEach { (e) in
                mutableAttributedString.addAttributes(
                    [
                        NSAttributedString.Key.font: UIFont.systemFont(
                            ofSize: font.pointSize, weight: .bold
                        ).rounded()
                    ], range: NSMakeRange(e.indices[0], e.indices[1] - e.indices[0]))
            }
        }

        return mutableAttributedString
    }
}
