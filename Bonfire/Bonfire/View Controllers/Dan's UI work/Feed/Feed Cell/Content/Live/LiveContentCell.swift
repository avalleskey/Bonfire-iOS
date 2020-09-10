//
//  LiveContentCell.swift
//  Bonfire
//
//  Created by Daniel Gauthier on 2020-08-24.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit
import Cartography

class LiveContentCell: UICollectionViewCell {

    var camp: DummyPost.Camp! {
        didSet {
            layoutIfNeeded()
            switch camp.liveType {
            case .audio:
                liveTypeLabel.text = "🎙"
            case .video:
                liveTypeLabel.text = "📹"
            case .chat:
                liveTypeLabel.text = "💬"
            default:
                break
            }

            borderedAvatarView.liveType = camp.liveType
            borderedAvatarView.image = camp.image
        }
    }

    private var borderedAvatarView = BorderedAvatarView(interiorBorderWidth: .thin, liveBorderWidth: .thick)
    private var liveTypeView = UIView(backgroundColor: .systemBackground, height: 28, width: 28, cornerRadius: 14)
    private var liveTypeLabel = UILabel(size: 12, weight: .regular, alignment: .center, multiline: false)

    override init(frame: CGRect) {
        super.init(frame: .zero)

        setUpBorderedAvatarView()
        setUpLiveTypeView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpBorderedAvatarView() {
        contentView.addSubview(borderedAvatarView)
        constrain(borderedAvatarView) {
            $0.width == 68
            $0.height == 68
            $0.edges == inset($0.superview!.edges, 7)
        }
    }

    private func setUpLiveTypeView() {
        contentView.addSubview(liveTypeView)
        constrain(liveTypeView) {
            $0.trailing == $0.superview!.trailing
            $0.bottom == $0.superview!.bottom
        }

        liveTypeView.addSubview(liveTypeLabel)
        constrain(liveTypeLabel) {
            $0.center == $0.superview!.center
        }

        liveTypeView.applyShadow(intensity: .sketch(color: .black, alpha: 0.12, x: 0, y: 2, blur: 2, spread: 0))
    }
}
