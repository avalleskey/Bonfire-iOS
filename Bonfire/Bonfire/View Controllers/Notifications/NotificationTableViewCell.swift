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
import Kingfisher

final class NotificationTableViewCell: UITableViewCell {

    static let reuseIdentifier = "NotificationTableViewCellReuseIdentifier"

    private var type: UserActivityType = .unknown {
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

    func updateWithNotification(notification: UserActivity) {
        type = UserActivityType(rawValue: notification.attributes.type) ?? .unknown
        read = notification.attributes.read

        if let title = notification.attributes.title {
            titleLabel.attributedText = .entityString(
                string: title.title, entities: title.entities)
        } else {
            titleLabel.text = ""
        }

        dateLabel.text = notification.attributes.createdAt.timeAgoDisplay()

        if let actioner = notification.attributes.actioner,
           let url = actioner.attributes.media?.avatar?.full?.url {
            profileImageView.kf.setImage(with: url)
        } else {
            profileImageView.image = nil
            profileImageView.backgroundColor = .gray
        }
        
        if let post = notification.attributes.post, let postMedia = post.attributes.attachments?.media, postMedia.count > 0 {
            previewPostImageContainerView.isHidden = false
            previewPostImageView.kf.setImage(with: postMedia[0].attributes.hostedVersions.full?.url)
        } else {
            previewPostImageContainerView.isHidden = true
            previewPostImageView.image = nil
        }
    }
    
    var read: Bool = false {
        didSet {
            unreadDotContainerView.isHidden = false//read
        }
    }

    let profileImageView: RoundedImageView = {
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

    let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Abayo Stevens reacted to your post"
        label.font = UIFont.systemFont(ofSize: 17, weight: .bold).rounded()
        label.textColor = Constants.Color.primary
        label.numberOfLines = 0
//        label.backgroundColor = UIColor(white: 0.8, alpha: 0.3)
        label.setContentHuggingPriority(UILayoutPriority(250), for: .vertical)
        return label
    }()

    let dateLabel: UILabel = {
        let label = UILabel()
        label.text = "2h ago"
        label.font = UIFont.systemFont(ofSize: 15, weight: .semibold).rounded()
        label.textColor = Constants.Color.secondary
//        label.backgroundColor = UIColor(white: 0.8, alpha: 0.3)
        label.setContentHuggingPriority(UILayoutPriority(250), for: .vertical)
        return label
    }()
    
    let textStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 2
        stackView.backgroundColor = UIColor(white: 0.8, alpha: 0.3)
        stackView.distribution = .fill
        stackView.alignment = .fill
        return stackView
    }()
    
    let topSpacerView: UIView = {
        let view = UIView()
        view.setContentHuggingPriority(UILayoutPriority(rawValue: 249), for: .vertical)
        view.backgroundColor = .blue
        view.frame = CGRect(x: 0, y: 0, width: 1, height: 0)
        return view
    }()
    let bottomSpacerView: UIView = {
        let view = UIView()
        view.setContentHuggingPriority(UILayoutPriority(rawValue: 249), for: .vertical)
        view.backgroundColor = .yellow
        view.frame = CGRect(x: 0, y: 0, width: 1, height: 0)
        return view
    }()
    
    let previewPostImageContainerView: UIView = {
        let view = UIView()
        return view
    }()
    let previewPostImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "Austin")!
        imageView.layer.cornerRadius = 6
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = UIColor(white: 0.2, alpha: 0.1)
        return imageView
    }()
    
    let unreadDotContainerView: UIView = {
        let view = UIView()
        return view
    }()
    let unreadDotView: RoundedView = {
        let view = RoundedView()
        view.backgroundColor = .systemBlue
        return view
    }()

    let detailsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 8
//        stackView.backgroundColor = UIColor(white: 0.2, alpha: 0.1)
        stackView.alignment = .top
        stackView.distribution = .fill
        return stackView
    }()
    
    let containerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
//        stackView.backgroundColor = .red
        stackView.alignment = .top
        stackView.distribution = .fill
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

//        textStackView.addArrangedSubview(topSpacerView)
        textStackView.addArrangedSubview(titleLabel)
        textStackView.addArrangedSubview(dateLabel)
        textStackView.setContentHuggingPriority(UILayoutPriority(750), for: .vertical)
        
        containerStackView.addArrangedSubview(textStackView)
        containerStackView.addArrangedSubview(bottomSpacerView)
        detailsStackView.addArrangedSubview(containerStackView)
        
        previewPostImageContainerView.addSubview(previewPostImageView)
        detailsStackView.addArrangedSubview(previewPostImageContainerView)
        
        unreadDotContainerView.addSubview(unreadDotView)
        detailsStackView.addArrangedSubview(unreadDotContainerView)
        
        contentView.addSubview(detailsStackView)

        updateConstraints()
    }

    override func updateConstraints() {
        super.updateConstraints()

        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        typeImageView.translatesAutoresizingMaskIntoConstraints = false
        detailsStackView.translatesAutoresizingMaskIntoConstraints = false
        textStackView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        topSpacerView.translatesAutoresizingMaskIntoConstraints = false
        bottomSpacerView.translatesAutoresizingMaskIntoConstraints = false
        previewPostImageView.translatesAutoresizingMaskIntoConstraints = false
        unreadDotView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            profileImageView.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor,
                constant: 12),
            profileImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            profileImageView.widthAnchor.constraint(equalToConstant: 64),
            profileImageView.heightAnchor.constraint(equalTo: profileImageView.widthAnchor),

            typeImageView.trailingAnchor.constraint(
                equalTo: profileImageView.trailingAnchor),
            typeImageView.bottomAnchor.constraint(
                equalTo: profileImageView.bottomAnchor),
            typeImageView.widthAnchor.constraint(equalToConstant: 24),
            typeImageView.heightAnchor.constraint(equalTo: typeImageView.widthAnchor),
            
            detailsStackView.leadingAnchor.constraint(
                equalTo: profileImageView.trailingAnchor,
                constant: 12),
            detailsStackView.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
                constant: -12),
            detailsStackView.topAnchor.constraint(equalTo: profileImageView.topAnchor),
            detailsStackView.heightAnchor.constraint(equalTo: textStackView.heightAnchor),
                        
            previewPostImageContainerView.widthAnchor.constraint(equalToConstant: 44),
            previewPostImageContainerView.heightAnchor.constraint(equalTo: profileImageView.heightAnchor),
            previewPostImageView.centerYAnchor.constraint(equalTo: previewPostImageContainerView.centerYAnchor),
            previewPostImageView.widthAnchor.constraint(equalTo: previewPostImageContainerView.widthAnchor),
            previewPostImageView.heightAnchor.constraint(equalTo: previewPostImageView.widthAnchor),

            unreadDotContainerView.widthAnchor.constraint(equalToConstant: 12),
            unreadDotContainerView.heightAnchor.constraint(equalTo: profileImageView.heightAnchor),
            unreadDotView.centerYAnchor.constraint(equalTo: unreadDotContainerView.centerYAnchor),
            unreadDotView.widthAnchor.constraint(equalTo: unreadDotContainerView.widthAnchor),
            unreadDotView.heightAnchor.constraint(equalTo: unreadDotView.widthAnchor),

            contentView.bottomAnchor.constraint(
                greaterThanOrEqualTo: detailsStackView.bottomAnchor,
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
