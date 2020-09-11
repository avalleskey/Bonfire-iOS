//
//  PostContentView.swift
//  Bonfire
//
//  Created by Daniel Gauthier on 2020-08-21.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import BFCore
import UIKit
import Cartography

class PostContentView: UIView {

    private var post: Post

    private var stackView = UIStackView(axis: .vertical, spacing: 12)
    private let postLabel = UILabel(size: 18, weight: .medium, multiline: true)
    private let attachmentContainerView = UIView(height: 200, cornerRadius: 14)

    init(post: Post) {
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

        if let message = post.attributes.message {
            postLabel.text = String(htmlEncodedString: message)
        } else {
            postLabel.isHidden = true
        }

        if post.attributes.attachments == nil {
            attachmentContainerView.isHidden = true
        } else {
            arrangeAttachments()
        }

        attachmentContainerView.clipsToBounds = true
        if #available(iOS 13.0, *) { attachmentContainerView.layer.cornerCurve = .continuous }

        postLabel.setContentCompressionResistancePriority(.required, for: .vertical)
    }

    private func arrangeAttachments() {
        guard let media = post.attributes.attachments?.media else { return }

        if media.count <= 2 {
            let stackView = UIStackView(axis: .horizontal, distribution: .fillEqually, spacing: 4)
            for item in media {
                let imageView = UIImageView(contentMode: .scaleAspectFill)
                imageView.kf.setImage(with: item.attributes.hostedVersions.full?.url)
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
            for item in media.enumerated() {
                let imageView = UIImageView(contentMode: .scaleAspectFill)
                imageView.kf.setImage(with: item.element.attributes.hostedVersions.full?.url)
                imageView.clipsToBounds = true
                if item.offset % 2 == 0 {
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
