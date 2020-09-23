//
//  CampMemberCell.swift
//  Bonfire
//
//  Created by Daniel Gauthier on 2020-09-08.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import BFCore
import Cartography
import UIKit

class CampMemberCell: UITableViewCell {

    // TODO: all the data about the last message in a conversation, whether it's been read, whether someone is typing, etc is
    // all crammed pretty nonsensically into this dummy User type right now for the sake of building and testing the Messages UI.
    // The way that this data should actually be fed into a ConversationCell still needs to be thought through, and is
    // ultimately dependent on how exactly the cloud delivers this data.
    var user: User! {
        didSet {
            borderedAvatarView.imageURL = user.attributes.media?.avatar?.full?.url
            userIdentityView.user = user

            detailLabel.text = detailLabelText()
            detailLabel.textColor = .secondaryText
            detailLabel.font = UIFont.systemFont(ofSize: 15, weight: .bold).rounded()
            
            let color = user.attributes.uiColor
            followButton.backgroundColor = color
            followButton.tintColor = (color.isDarkColor ? .white : .black)
            followButton.setTitleColor(followButton.tintColor, for: .normal)
        }
    }
    private func detailLabelText() -> String {
        var detail = ""
        if user.attributes.context?.camp?.membership?.role?.type == .admin {
            detail = "Admin · "
        }
        else if user.attributes.context?.camp?.membership?.role?.type == .moderator {
            detail = "Moderator · "
        }
        
        if let joinedAt = user.attributes.context?.camp?.membership?.joinedAt {
            detail.append("Joined \(joinedAt.timeAgoDisplay())")
        } else {
            detail.append("Camper")
        }
        // TODO: Display "You" if it's the current user
        
        return detail
    }

    private let borderedAvatarView = BorderedAvatarView()
    private let userIdentityView = UserIdentityView()
    private let detailLabel = UILabel(size: 15, weight: .bold, color: .secondaryText, multiline: false)
    private let detailStackView = UIStackView(axis: .horizontal, alignment: .center, spacing: 6)
    private let followButton = BFBouncyButton(image: UIImage(named: "PlusIcon"), backgroundColor: Constants.Color.primary, title: "Add", width: 82, height: 40, cornerRadius: 12, systemButton: false)

    let separatorView = UIView(backgroundColor: Constants.Color.separatorColor, height: 1 / UIScreen.main.scale)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        selectionStyle = .none
        backgroundColor = .clear
        
        setUpBorderedAvatarView()
        setUpFollowButton()
        setUpContent()
        setUpSeparatorView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    private func setUpBorderedAvatarView() {
        contentView.addSubview(borderedAvatarView)
        constrain(borderedAvatarView) {
            $0.width == 48
            $0.height == 48
            $0.leading == $0.superview!.leading + 12
            $0.top == $0.superview!.top + 12
            $0.bottom == $0.superview!.bottom - 12 ~ .init(999)
        }
    }

    private func setUpFollowButton() {
        if #available(iOS 13.0, *) {
            followButton.layer.cornerCurve = .continuous
        }
        followButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold).rounded()
        followButton.titleEdgeInsets.left = 4
        followButton.imageEdgeInsets.right = 4
        followButton.layer.shadowOffset = CGSize(width: 0, height: 1)
        followButton.layer.shadowRadius = 2
        followButton.layer.shadowOpacity = 0.08
        followButton.layer.shadowColor = UIColor.black.cgColor
        contentView.addSubview(followButton)
        constrain(followButton) {
            $0.centerY == $0.superview!.centerY
            $0.trailing == $0.superview!.trailing - 12
        }
    }

    private func setUpContent() {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(userIdentityView)
        containerView.addSubview(detailStackView)

        constrain(userIdentityView) {
            $0.leading == $0.superview!.leading
            $0.top == $0.superview!.top
            $0.trailing <= $0.superview!.trailing
        }

        constrain(detailStackView, userIdentityView) {
            $0.top == $1.bottom + 2
            $0.leading == $0.superview!.leading
            $0.trailing <= $0.superview!.trailing
            $0.bottom == $0.superview!.bottom
        }

        detailStackView.addArrangedSubview(detailLabel)

        containerView.clipsToBounds = true
        contentView.addSubview(containerView)
        constrain(containerView, borderedAvatarView, followButton) {
            $0.leading == $1.trailing + 12
            $0.centerY == $1.centerY
            $0.trailing == $2.leading - 12
        }

        followButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        detailLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
    }

    private func setUpSeparatorView() {
        contentView.addSubview(separatorView)
        constrain(separatorView, userIdentityView) {
            $0.leading == $1.leading
            $0.trailing == $0.superview!.trailing
            $0.bottom == $0.superview!.bottom
        }
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
