//
//  ConversationCell.swift
//  Bonfire
//
//  Created by Daniel Gauthier on 2020-09-08.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import BFCore
import Cartography
import UIKit

class ConversationCell: UITableViewCell {

    // TODO: all the data about the last message in a conversation, whether it's been read, whether someone is typing, etc is
    // all crammed pretty nonsensically into this dummy User type right now for the sake of building and testing the Messages UI.
    // The way that this data should actually be fed into a ConversationCell still needs to be thought through, and is
    // ultimately dependent on how exactly the cloud delivers this data.
    var user: DummyPost.User! {
        didSet {
            borderedAvatarView.image = user.image
            userIdentityView.user = user

            if user.isTyping {
                detailLabel.text = "Typing..."
                detailLabel.textColor = .secondaryGray
                detailLabel.font = UIFont.systemFont(ofSize: 15, weight: .bold).rounded()
                newDotView.isHidden = true
                separatorDotView.isHidden = true
                timeLabel.isHidden = true
            } else if let lastMessage = user.lastMessage {
                separatorDotView.isHidden = false
                timeLabel.isHidden = false
                timeLabel.text = formattedExpiry(date: lastMessage.date)
                if lastMessage.isOwnMessage {
                    detailLabel.text = "You: \(lastMessage.text)"
                    detailLabel.textColor = .secondaryGray
                    detailLabel.font = UIFont.systemFont(ofSize: 15, weight: .bold).rounded()
                    newDotView.isHidden = true
                } else {
                    detailLabel.text = lastMessage.text
                    if lastMessage.isRead {
                        detailLabel.textColor = .secondaryGray
                        detailLabel.font = UIFont.systemFont(ofSize: 15, weight: .bold).rounded()
                        newDotView.isHidden = true
                    } else {
                        detailLabel.textColor = user.color
                        detailLabel.font = UIFont.systemFont(ofSize: 15, weight: .heavy).rounded()
                        newDotView.backgroundColor = user.color
                        newDotView.isHidden = false
                    }
                }

            } else {
                detailLabel.text = "No messages"
                detailLabel.textColor = .secondaryGray
                newDotView.isHidden = true
                separatorDotView.isHidden = true
                timeLabel.isHidden = true
            }

            switch user.favoriteLevel {
                case 3: heartLabel.text = "❤️"
                case 2: heartLabel.text = "🧡"
                case 1: heartLabel.text = "💛"
                default: heartLabel.text = ""
            }
        }
    }

    private let borderedAvatarView = BorderedAvatarView()
    private let userIdentityView = UserIdentityView()
    private let newDotView = UIView(backgroundColor: .onlineGreen, height: 11, width: 11, cornerRadius: 5.5)
    private let detailLabel = UILabel(size: 15, weight: .bold, multiline: false)
    private let separatorDotView = UIView(backgroundColor: UIColor.secondaryGray.withAlphaComponent(0.5), height: 3, width: 3, cornerRadius: 1.5)
    private let timeLabel = UILabel(size: 15, weight: .bold, color: .secondaryGray, multiline: false)
    private let detailStackView = UIStackView(axis: .horizontal, alignment: .center, spacing: 6)
    private let heartLabel = UILabel(size: 17, weight: .regular, multiline: false, text: "❤️")

    private let separatorView = UIView(backgroundColor: .separatorGray, height: 1 / UIScreen.main.scale)

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()

    private let weekFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "ccc"
        return formatter
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setUpBorderedAvatarView()
        setUpHeartLabel()
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

    private func setUpHeartLabel() {
        contentView.addSubview(heartLabel)
        constrain(heartLabel) {
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

        detailStackView.addArrangedSubview(newDotView)
        detailStackView.addArrangedSubview(detailLabel)
        detailStackView.addArrangedSubview(separatorDotView)
        detailStackView.addArrangedSubview(timeLabel)

        containerView.clipsToBounds = true
        contentView.addSubview(containerView)
        constrain(containerView, borderedAvatarView, heartLabel) {
            $0.leading == $1.trailing + 12
            $0.centerY == $1.centerY
            $0.trailing == $2.leading - 12
        }

        heartLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        timeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
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

    private func formattedExpiry(date: Date) -> String {
        let totalSeconds = abs(Int(date.timeIntervalSince(Date())))

        var string: String

        var hours = totalSeconds / 3600
        var minutes = Int(ceil(Float(totalSeconds % 3600) / 60))

        if minutes % 60 == 0 && minutes >= 60 {
            hours += minutes / 60
            minutes = 0
        }

        if totalSeconds < 60 {
            string = "just now"
        } else if hours == 0 {
            string = "\(minutes)m"
        } else if hours < 24 {
            string = "\(hours)h"
        } else if hours < 24 * 7 {
            string = weekFormatter.string(from: date)
        } else {
            string = dateFormatter.string(from: date)
        }

        return string
    }
}
