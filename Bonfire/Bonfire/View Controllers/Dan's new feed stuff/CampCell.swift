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
            let color = UIColor(hex: camp.attributes.color)!
            onlineLabel.textColor = color
            onlineDotView.backgroundColor = color
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
            case .newFires:
                borderedAvatarView.liveType = nil
                borderedAvatarView.liveBorderWidth = .none
                borderedAvatarView.interiorBorderWidth = .none
            case .creator:
                borderedAvatarView.liveType = nil
                borderedAvatarView.liveBorderWidth = .none
                borderedAvatarView.interiorBorderWidth = .none
            case .liveChat:
                borderedAvatarView.liveType = .chat
                borderedAvatarView.liveBorderWidth = .thin
                borderedAvatarView.interiorBorderWidth = .thin
            }
        }
    }

    private let borderedAvatarView = BorderedAvatarView()
    private let titleLabel = UILabel(size: 17, weight: .bold, color: .label)
    private let onlineDotView = UIView(backgroundColor: .onlineGreen, height: 11, width: 11, cornerRadius: 5.5)
    private let onlineLabel = UILabel(size: 15, weight: .heavy, color: .onlineGreen, multiline: false, text: "\(Int.random(in: 1...15000)) online")

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
        containerView.addSubview(onlineDotView)
        containerView.addSubview(onlineLabel)
        constrain(titleLabel) {
            $0.leading == $0.superview!.leading
            $0.top == $0.superview!.top
            $0.trailing == $0.superview!.trailing
        }

        constrain(onlineLabel, titleLabel) {
            $0.top == $1.bottom + 2
            $0.trailing == $0.superview!.trailing
            $0.bottom == $0.superview!.bottom
        }

        constrain(onlineDotView, onlineLabel) {
            $0.leading == $0.superview!.leading
            $0.trailing == $1.leading - 8
            $0.centerY == $1.centerY
        }

        contentView.addSubview(containerView)
        constrain(containerView, borderedAvatarView) {
            $0.leading == $1.trailing + 12
            $0.centerY == $1.centerY
        }

        constrain(containerView, memberSwitch) { $0.trailing <= $1.leading - 12 }
        constrain(containerView, shareButton) { $0.trailing <= $1.leading - 12 }
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
