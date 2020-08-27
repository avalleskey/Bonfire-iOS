//
//  PostContentView.swift
//  Bonfire
//
//  Created by Daniel Gauthier on 2020-08-21.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit
import Cartography

class PostContentView: UIView {

    private var post: DummyPost

    private var stackView = UIStackView(axis: .vertical, spacing: 12)
    private let postLabel = UILabel(size: 18, weight: .medium, multiline: true)
    private let attachmentContainerView = UIView(height: 200, cornerRadius: 14)

    init(post: DummyPost) {
        self.post = post
        super.init(frame: .zero)
        setUpStackView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpStackView() {
        addSubview(stackView)
        constrain(stackView) {
            $0.edges == inset($0.superview!.edges, 16, 0)
        }

        stackView.addArrangedSubview(postLabel)
        stackView.addArrangedSubview(attachmentContainerView)

        if let message = post.message {
            postLabel.text = message
        } else {
            postLabel.isHidden = true
        }

        if post.attachments.isEmpty {
            attachmentContainerView.isHidden = true
        } else {
            arrangeAttachments()
        }

        attachmentContainerView.clipsToBounds = true
        attachmentContainerView.layer.cornerCurve = .continuous

        postLabel.setContentCompressionResistancePriority(.required, for: .vertical)
    }

    private func arrangeAttachments() {
        if post.attachments.count <= 2 {
            let stackView = UIStackView(axis: .horizontal, distribution: .fillEqually, spacing: 4)
            for image in post.attachments {
                let imageView = UIImageView(image: image, contentMode: .scaleAspectFill)
                imageView.clipsToBounds = true
                stackView.addArrangedSubview(imageView)
            }
            attachmentContainerView.addSubview(stackView)
            constrain(stackView) {
                $0.edges == $0.superview!.edges
                $0.height == 200
            }
        } else {
            let horizontalStackView = UIStackView(axis: .horizontal, distribution: .fillEqually, spacing: 4)
            let firstVerticalStackView = UIStackView(axis: .vertical, distribution: .fillEqually, spacing: 4)
            let secondVerticalStackView = UIStackView(axis: .vertical, distribution: .fillEqually, spacing: 4)

            horizontalStackView.addArrangedSubview(firstVerticalStackView)
            horizontalStackView.addArrangedSubview(secondVerticalStackView)
            for image in post.attachments.enumerated() {
                let imageView = UIImageView(image: image.element, contentMode: .scaleAspectFill)
                imageView.clipsToBounds = true
                if image.offset % 2 == 0 {
                    secondVerticalStackView.addArrangedSubview(imageView)
                } else {
                    firstVerticalStackView.addArrangedSubview(imageView)
                }

                attachmentContainerView.addSubview(horizontalStackView)
                constrain(horizontalStackView) {
                    $0.edges == $0.superview!.edges
                    $0.height == 200
                }
            }
        }
    }
}
