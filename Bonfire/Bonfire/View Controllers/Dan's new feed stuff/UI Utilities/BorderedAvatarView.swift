//
//  BorderedAvatarView.swift
//  Bonfire
//
//  Created by Daniel Gauthier on 2020-08-24.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit
import Cartography

class BorderedAvatarView: UIView {

    enum BorderWidth: CGFloat {
        case thin = 3
        case thick = 4
    }

    var image: UIImage? {
        didSet {
            imageView.image = image
        }
    }
    private var imageView = UIImageView(contentMode: .scaleAspectFill)
    private var displayShadow: Bool

    init(image: UIImage? = nil, displayShadow: Bool = false, borderWidth: BorderWidth = .thin) {
        self.image = image
        self.displayShadow = displayShadow
        super.init(frame: .zero)

        backgroundColor = .white

        imageView.image = image
        addSubview(imageView)
        constrain(imageView) {
            $0.edges == inset($0.superview!.edges, borderWidth.rawValue)
        }
        imageView.layer.borderWidth = 0.5
        imageView.layer.borderColor = UIColor.black.withAlphaComponent(0.1).cgColor
        imageView.clipsToBounds = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = frame.height / 2.0
        imageView.layer.cornerRadius = imageView.frame.height / 2.0

        if displayShadow { applyShadow(intensity: .sketch(color: .black, alpha: 0.12, x: 0, y: 1, blur: 3, spread: 0)) }
    }
}
