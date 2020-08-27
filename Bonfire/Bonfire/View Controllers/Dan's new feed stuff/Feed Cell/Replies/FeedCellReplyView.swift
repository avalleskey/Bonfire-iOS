//
//  FeedCellReplyView.swift
//  Bonfire
//
//  Created by Daniel Gauthier on 2020-08-26.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit
import Cartography

class FeedCellReplyView: UIView {

    var replies: [DummyPost.Reply] = [] {
        didSet {
            for reply in replies {
                stackView.addArrangedSubview(ReplyCell(reply: reply))
            }
        }
    }

    private let stackView = UIStackView(axis: .vertical)

    init() {
        super.init(frame: .zero)
        setUpStackView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpStackView() {
        addSubview(stackView)
        constrain(stackView) {
            $0.top == $0.superview!.top
            $0.leading == $0.superview!.leading
            $0.trailing == $0.superview!.trailing
            $0.bottom == $0.superview!.bottom - 8
        }
    }

    func prepareForReuse() {
        stackView.arrangedSubviews.forEach {
            $0.removeFromSuperview()
        }
    }
}
