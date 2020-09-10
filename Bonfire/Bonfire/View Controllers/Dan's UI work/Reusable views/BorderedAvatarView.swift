//
//  BorderedAvatarView.swift
//  Bonfire
//
//  Created by Daniel Gauthier on 2020-08-24.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit
import Cartography

/*
 Note: this class intentionally allows its borders to extend beyond its bounds.
 Therefore, when setting the size of this view, you are just setting the size of the image itself.
 Similarly, when setting this view's position relative to other views, the image's edges are the relevant edges.
 */
class BorderedAvatarView: UIView {

    enum BorderWidth: CGFloat {
        case none = 0
        case thin = 3
        case thick = 4
    }

    var image: UIImage? {
        didSet {
            imageView.image = image
        }
    }

    var imageURL: URL? {
        didSet {
            imageView.kf.setImage(with: imageURL)
        }
    }

    var displayShadow: Bool
    var liveBorderWidth: BorderWidth {
        didSet {
            constrain(liveBorderView, replace: liveBorderEdgeConstraints) {
                $0.edges == inset($0.superview!.edges, -liveBorderWidth.rawValue - interiorBorderWidth.rawValue)
            }

            layoutIfNeeded()
        }
    }

    var interiorBorderWidth: BorderWidth {
        didSet {
            constrain(liveBorderView, replace: liveBorderEdgeConstraints) {
                $0.edges == inset($0.superview!.edges, -liveBorderWidth.rawValue - interiorBorderWidth.rawValue)
            }

            constrain(interiorBorderView, replace: interiorBorderEdgeConstraints) {
                $0.edges == inset($0.superview!.edges, -interiorBorderWidth.rawValue)
            }

            layoutIfNeeded()
        }
    }

    var liveType: DummyPost.Camp.LiveType? {
        didSet {
            setNeedsLayout()
            layoutIfNeeded()
        }
    }

    private var liveBorderView = UIView()
    private var interiorBorderView = UIView(backgroundColor: .white)
    private var imageView = UIImageView(contentMode: .scaleAspectFill)

    private var liveBorderEdgeConstraints = ConstraintGroup()
    private var interiorBorderEdgeConstraints = ConstraintGroup()


    init(image: UIImage? = nil, interiorBorderWidth: BorderWidth = .none, liveBorderWidth: BorderWidth = .none, liveType: DummyPost.Camp.LiveType? = nil, displayShadow: Bool = false) {
        self.image = image
        self.displayShadow = displayShadow
        self.liveBorderWidth = liveBorderWidth
        self.interiorBorderWidth = interiorBorderWidth
        self.liveType = liveType
        super.init(frame: .zero)

        clipsToBounds = false

        setUpLiveBorderView()
        setUpInteriorBorderView()
        setUpImageView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpLiveBorderView() {
        addSubview(liveBorderView)
        constrain(liveBorderView, replace: liveBorderEdgeConstraints) {
            $0.edges == inset($0.superview!.edges, -liveBorderWidth.rawValue - interiorBorderWidth.rawValue)
        }
    }

    private func setUpInteriorBorderView() {
        addSubview(interiorBorderView)
        constrain(interiorBorderView, replace: interiorBorderEdgeConstraints) {
            $0.edges == inset($0.superview!.edges, -interiorBorderWidth.rawValue)
        }
    }

    private func setUpImageView() {
        addSubview(imageView)
        constrain(imageView) {
            $0.edges == $0.superview!.edges
        }

        imageView.layer.borderWidth = (1 / UIScreen.main.scale)
        imageView.layer.borderColor = UIColor.black.withAlphaComponent(0.1).cgColor
        imageView.clipsToBounds = true
        imageView.image = image
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.layer.cornerRadius = imageView.frame.height / 2.0
        liveBorderView.layer.cornerRadius = liveBorderView.frame.height / 2.0
        interiorBorderView.layer.cornerRadius = interiorBorderView.frame.height / 2.0

        if displayShadow { applyShadow(intensity: .sketch(color: .black, alpha: 0.12, x: 0, y: 1, blur: 3, spread: 0)) }
        if liveBorderWidth != .none, let liveType = liveType {
            liveBorderView.applyGradient(colors: liveType.gradientColors)
        }
    }
}
