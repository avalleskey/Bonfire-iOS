//
//  CampCell.swift
//  Bonfire
//
//  Created by Daniel Gauthier on 2020-09-03.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import BFCore
import Cartography
import UIKit

class CampCell: UITableViewCell {

    var camp: Camp! {
        didSet {
            borderedAvatarView.imageURL = camp.attributes.media?.avatar?.full?.url
            titleLabel.text = camp.attributes.title
        }
    }

    var isFeaturedCamp = false {
        didSet {
            memberSwitch.isHidden = !isFeaturedCamp
            shareButton.isHidden = isFeaturedCamp
        }
    }

    // TODO: this is a temporary type used to test various ways a camp can be presented.
    // This should ultimately be driven by some combination of cloud data and client-side logic.
    enum DisplayType: CaseIterable {
        case newFires
        case liveChat
        case creator
        case onlineCount
    }

    var displayType: DisplayType = .onlineCount {
        didSet {
            switch displayType {
            case .onlineCount:
                borderedAvatarView.liveType = nil
                borderedAvatarView.liveBorderWidth = .none
                borderedAvatarView.interiorBorderWidth = .none
                detailLabel.text = "\(Int.random(in: 1...15000)) online"
                detailLabel.font = UIFont.systemFont(ofSize: 15, weight: .bold).rounded()
                emojiLabel.isHidden = true
                newDotView.isHidden = true
                detailBackingView.removeGradient()
                detailBackingView.backgroundColor = .onlineGreen
            case .newFires:
                borderedAvatarView.liveType = nil
                borderedAvatarView.liveBorderWidth = .none
                borderedAvatarView.interiorBorderWidth = .none
                detailLabel.text = "New Fires"
                detailLabel.font = UIFont.systemFont(ofSize: 15, weight: .heavy).rounded()
                emojiLabel.isHidden = true
                newDotView.isHidden = false
                newDotView.backgroundColor = UIColor(hex: camp.attributes.color)!
                detailBackingView.removeGradient()
                detailBackingView.backgroundColor = UIColor(hex: camp.attributes.color)!
            case .creator:
                borderedAvatarView.liveType = nil
                borderedAvatarView.liveBorderWidth = .none
                borderedAvatarView.interiorBorderWidth = .none
                detailLabel.text = "by @austin"
                detailLabel.font = UIFont.systemFont(ofSize: 15, weight: .bold).rounded()
                emojiLabel.isHidden = true
                newDotView.isHidden = true
                detailBackingView.removeGradient()
                detailBackingView.backgroundColor = .secondaryGray
            case .liveChat:
                borderedAvatarView.liveType = .chat
                borderedAvatarView.liveBorderWidth = .thin
                borderedAvatarView.interiorBorderWidth = .thin
                detailLabel.text = "Live Chat"
                detailLabel.font = UIFont.systemFont(ofSize: 15, weight: .heavy).rounded()
                detailLabel.textColor = .white
                emojiLabel.isHidden = false
                newDotView.isHidden = true

                let textSize = ("Live Chat" as NSString).size(withAttributes: [.font: UIFont.systemFont(ofSize: 15, weight: .heavy).rounded()])
                DispatchQueue.main.async {
                    self.detailBackingView.applyGradient(colors: [.liveChatTop, .liveChatBottom], startPoint: CGPoint(x: 0, y: 0.5), endPoint: CGPoint(x: textSize.width / self.detailBackingView.frame.width, y: 0.5))
                }
            }

            self.layoutIfNeeded()
            self.detailBackingView.mask = self.detailLabel
        }
    }

    private let borderedAvatarView = BorderedAvatarView()
    private let titleLabel = UILabel(size: 17, weight: .bold, color: .label)
    private let newDotView = UIView(backgroundColor: .onlineGreen, height: 11, width: 11, cornerRadius: 5.5)
    private let emojiLabel = UILabel(size: 10, weight: .bold, multiline: false, text: "💬")
    private let detailLabel = UILabel(size: 15, weight: .bold, multiline: false)
    private let detailBackingView = UIView(backgroundColor: .label)
    private let detailStackView = UIStackView(axis: .horizontal, alignment: .center, spacing: 4)

    private let memberSwitch: UISwitch = {
        let memberSwitch = UISwitch()
        memberSwitch.onTintColor = .onlineGreen
        memberSwitch.translatesAutoresizingMaskIntoConstraints = false
        return memberSwitch
    }()

    private let shareButton = UIButton(image: UIImage(named: "ShareIcon"), contentColor: .label, backgroundColor: UIColor(hex: "1C1C1E")!.withAlphaComponent(0.03), width: 36, height: 36, cornerRadius: 18, systemButton: true)

    private let separatorView = UIView(backgroundColor: .separatorGray, height: 1 / UIScreen.main.scale)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setUpBorderedAvatarView()
        setUpMemberSwitch()
        setUpShareButton()
        setUpText()
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

    private func setUpMemberSwitch() {
        contentView.addSubview(memberSwitch)
        constrain(memberSwitch) {
            $0.trailing == $0.superview!.trailing - 12
            $0.centerY == $0.superview!.centerY
        }

        memberSwitch.isHidden = true
    }

    private func setUpShareButton() {
        contentView.addSubview(shareButton)
        constrain(shareButton) {
            $0.trailing == $0.superview!.trailing - 12
            $0.centerY == $0.superview!.centerY
        }
    }

    private func setUpText() {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(titleLabel)
        containerView.addSubview(detailStackView)

        constrain(titleLabel) {
            $0.leading == $0.superview!.leading
            $0.top == $0.superview!.top
            $0.trailing == $0.superview!.trailing
        }

        constrain(detailStackView, titleLabel) {
            $0.top == $1.bottom + 2
            $0.leading == $0.superview!.leading
            $0.trailing == $0.superview!.trailing
            $0.bottom == $0.superview!.bottom
        }

        detailStackView.addArrangedSubview(newDotView)
        detailStackView.addArrangedSubview(emojiLabel)
        detailStackView.addArrangedSubview(detailBackingView)

        constrain(emojiLabel) { $0.width == 14 }

        detailBackingView.addSubview(detailLabel)
        constrain(detailLabel) {
            $0.edges == $0.superview!.edges
        }

        containerView.clipsToBounds = true
        contentView.addSubview(containerView)
        constrain(containerView, borderedAvatarView) {
            $0.leading == $1.trailing + 12
            $0.centerY == $1.centerY
        }

        constrain(containerView, memberSwitch) { $0.trailing == $1.leading - 12 }
    }

    private func setUpSeparatorView() {
        contentView.addSubview(separatorView)
        constrain(separatorView, titleLabel) {
            $0.leading == $1.leading
            $0.trailing == $0.superview!.trailing
            $0.bottom == $0.superview!.bottom
        }
    }
}
