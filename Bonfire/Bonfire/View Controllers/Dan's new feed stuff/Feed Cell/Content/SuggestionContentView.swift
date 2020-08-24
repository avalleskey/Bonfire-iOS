//
//  SuggestionContentView.swift
//  Bonfire
//
//  Created by Daniel Gauthier on 2020-08-21.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit
import Cartography

class SuggestionContentView: UIView {

    private var suggestion: Suggestable

    private let containerView = UIView(backgroundColor: UIColor.systemTeal, height: 170, cornerRadius: 14)
    private let borderedAvatarView = BorderedAvatarView(displayShadow: true, borderWidth: .thick)
    private let nameLabel = UILabel(size: 20, weight: .bold, color: .white, alignment: .center, multiline: false)
    private let detailLabel = UILabel(size: 14, weight: .bold, color: .white, alignment: .center, multiline: false)

    init(suggestion: Suggestable) {
        self.suggestion = suggestion
        super.init(frame: .zero)
        setUpContainerView()
        setUpBorderedAvatarView()
        setUpNameLabel()
        setUpDetailLabel()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpContainerView() {
        addSubview(containerView)
        constrain(containerView) {
            $0.edges == inset($0.superview!.edges, horizontally: 16)
        }

        containerView.backgroundColor = suggestion.color
    }

    private func setUpBorderedAvatarView() {
        containerView.addSubview(borderedAvatarView)
        constrain(borderedAvatarView) {
            $0.centerX == $0.superview!.centerX
            $0.top == $0.superview!.top + 24
            $0.width == 72
            $0.height == 72
        }

        borderedAvatarView.image = suggestion.image
    }

    private func setUpNameLabel() {
        containerView.addSubview(nameLabel)
        constrain(nameLabel, borderedAvatarView) {
            $0.centerX == $0.superview!.centerX
            $0.top == $1.bottom + 5
        }

        nameLabel.text = suggestion.name
    }

    private func setUpDetailLabel() {
        containerView.addSubview(detailLabel)
        constrain(detailLabel, nameLabel) {
            $0.centerX == $0.superview!.centerX
            $0.top == $1.bottom + 2
        }

        detailLabel.text = suggestion.suggestionDetail
    }
}
