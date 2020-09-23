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
    private let attachmentContainerView = UIStackView(cornerRadius: 14)

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
        if let message = post.attributes.message {
            postLabel.isHidden = message.count == 0
            postLabel.text = String(htmlEncodedString: message)
            
            if message.containsOnlyEmoji && message.count <= 3 {
                postLabel.font = UIFont.systemFont(ofSize: 48)
            } else {
                postLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
            }
        } else {
            postLabel.isHidden = true
        }
        
        attachmentContainerView.axis = .vertical
        attachmentContainerView.distribution = .fill
        attachmentContainerView.alignment = .top
        stackView.addArrangedSubview(attachmentContainerView)

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
        guard let attachments = post.attributes.attachments else { return }

        let attachmentCornerRadius: CGFloat = 14
        if let link = attachments.link {
            let linkStackView = UIStackView(axis: .vertical)
            linkStackView.backgroundColor = Constants.Color.secondaryFill
            linkStackView.layer.borderColor = linkStackView.backgroundColor?.cgColor
            linkStackView.layer.borderWidth = 1
            linkStackView.layer.cornerRadius = attachmentCornerRadius
            if #available(iOS 13.0, *) {
                linkStackView.layer.cornerCurve = .continuous
            }
            
            if let images = link.attributes.images {
                if images.count > 0 {
                    let image = images[0]
                    
                    let imageView = UIImageView(contentMode: .scaleAspectFill)
                    imageView.clipsToBounds = true
                    imageView.backgroundColor = Constants.Color.systemBackground
                    imageView.kf.setImage(with: image)
                    linkStackView.addArrangedSubview(imageView)
                    constrain(imageView) {
                        $0.width == $0.superview!.width
                        $0.height == 140
                    }
                }
            }
            
            let detailsStackView = UIStackView(axis: .vertical, alignment: .leading, spacing: 2)
            detailsStackView.layoutMargins = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
            detailsStackView.isLayoutMarginsRelativeArrangement = true
            if let linkTitle = link.attributes.title {
                let label = UILabel(size: 17, weight: .semibold, color: Constants.Color.primary, text: linkTitle)
                label.numberOfLines = 2
                label.lineBreakMode = .byTruncatingTail
                detailsStackView.addArrangedSubview(label)
            }
            
            let detail = link.attributes.theDescription ?? link.attributes.canonicalUrl
            
            let label = UILabel(size: 17, weight: .regular, color: Constants.Color.secondary, text: detail)
            label.numberOfLines = 1
            label.lineBreakMode = .byTruncatingTail
            detailsStackView.addArrangedSubview(label)
            
            linkStackView.addArrangedSubview(detailsStackView)
            
            attachmentContainerView.addArrangedSubview(linkStackView)
            
            constrain(detailsStackView) {
                $0.width == $0.superview!.width
            }
            constrain(linkStackView) {
                $0.width == $0.superview!.width
            }
        } else if let media = attachments.media {
            if media.count <= 2 {
                let mediaStackView = UIStackView(axis: .horizontal, distribution: .fillEqually, spacing: 4)
                for item in media {
                    let imageView = UIImageView(contentMode: .scaleAspectFill)
                    imageView.kf.setImage(with: item.attributes.hostedVersions.full?.url)
                    imageView.clipsToBounds = true
                    mediaStackView.addArrangedSubview(imageView)
                }
                attachmentContainerView.addArrangedSubview(mediaStackView)
                constrain(mediaStackView) {
                    $0.width == $0.superview!.width
                    $0.height == 375-32
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

                    attachmentContainerView.addArrangedSubview(horizontalStackView)
                    constrain(horizontalStackView) {
                        $0.width == $0.superview!.width
                        $0.height == 375-32
                    }
                }
            }
        }
    }
}
