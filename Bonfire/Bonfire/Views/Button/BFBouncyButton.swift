//
//  BFBouncyButton.swift
//  Bonfire
//
//  Created by Austin Valleskey on 7/17/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit

class BFBouncyButton: UIButton {

    var haptics: Bool = true
    
    override init(frame: CGRect) {
        super.init(frame: .zero)

        adjustsImageWhenHighlighted = false

        addTarget(
            self,
            action: #selector(animateDown),
            for: [.touchDown, .touchDragEnter])
        addTarget(
            self,
            action: #selector(animateUp),
            for: [.touchDragExit, .touchCancel, .touchUpInside, .touchUpOutside])
    }

    @objc private func animateDown(sender: UIButton) {
        if haptics {
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
        }

        animate(sender, transform: CGAffineTransform.identity.scaledBy(x: 0.9, y: 0.9))
    }

    @objc private func animateUp(sender: UIButton) {
        animate(sender, transform: .identity)
    }

    private func animate(_ button: UIButton, transform: CGAffineTransform) {
        UIView.animate(
            withDuration: 0.4,
            delay: 0,
            usingSpringWithDamping: 0.5,
            initialSpringVelocity: 3,
            options: [.curveEaseInOut],
            animations: {
                button.transform = transform
            })
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
