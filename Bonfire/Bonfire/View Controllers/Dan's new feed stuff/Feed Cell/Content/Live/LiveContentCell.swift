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
                backingView.applyGradient(colors: [.liveAudioTop, .liveAudioBottom], startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: 1, y: 1))
                liveTypeLabel.text = "🎙"
            case .video:
                backingView.applyGradient(colors: [.liveVideoTop, .liveVideoBottom], startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: 1, y: 1))
                liveTypeLabel.text = "📹"
            case .chat:
                backingView.applyGradient(colors: [.liveChatTop, .liveChatBottom], startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: 1, y: 1))
                liveTypeLabel.text = "💬"
            default:
                break
            }

            borderedAvatarView.image = camp.image
        }
    }

    private var backingView = UIView(height: 80, width: 80, cornerRadius: 40)
    private var borderedAvatarView = BorderedAvatarView()
    private var liveTypeView = UIView(backgroundColor: .systemBackground, height: 28, width: 28, cornerRadius: 14)
    private var liveTypeLabel = UILabel(size: 12, weight: .regular, alignment: .center, multiline: false)

    override init(frame: CGRect) {
        super.init(frame: .zero)

        setUpBackingView()
        setUpBorderedAvatarView()
        setUpLiveTypeView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpBackingView() {
        contentView.addSubview(backingView)
        constrain(backingView) {
            $0.edges == $0.superview!.edges
        }
        backingView.layer.masksToBounds = true
    }

    private func setUpBorderedAvatarView() {
        contentView.addSubview(borderedAvatarView)
        constrain(borderedAvatarView) {
            $0.width == 72
            $0.height == 72
            $0.center == $0.superview!.center
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
