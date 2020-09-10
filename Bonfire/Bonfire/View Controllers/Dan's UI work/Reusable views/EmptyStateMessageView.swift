//
//  EmptyStateMessageView.swift
//  Bonfire
//
//  Created by Daniel Gauthier on 2020-09-02.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit
import Cartography

class EmptyStateMessageView: UIView {

    private let stackView = UIStackView(axis: .vertical, spacing: 2)
    private let titleLabel = UILabel(size: 20, weight: .bold, color: .secondaryLabel, alignment: .center)
    private let subtitleLabel = UILabel(size: 16, weight: .medium, color: .secondaryLabel, alignment: .center)

    init(title: String? = nil, subtitle: String? = nil) {
        super.init(frame: .zero)

        addSubview(stackView)
        constrain(stackView) {
            $0.edges == $0.superview!.edges
        }

        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(subtitleLabel)

        titleLabel.text = title
        subtitleLabel.text = subtitle

        titleLabel.isHidden = title == nil
        subtitleLabel.isHidden = subtitle == nil
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
