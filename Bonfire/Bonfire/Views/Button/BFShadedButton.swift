//
//  BFShadedButton.swift
//  Bonfire
//
//  Created by Austin Valleskey on 9/14/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit

class BFShadedButton: UIButton {
    
    enum BounceIntensity: CGFloat {
        case normal = 5.0
        case low = 2.0
        case none = 0.0
    }
    
    var tint: UIColor = Constants.Color.primary {
        didSet {
            tintColor = tint
                        
            let light: UIColor = tint.withAlphaComponent(0.03)
            let light_highlight: UIColor = tint.withAlphaComponent(0.06)
            
            let dark: UIColor = tint.withAlphaComponent(0.12)
            let dark_highlight: UIColor = tint.withAlphaComponent(0.24)

            color = UIColor.dynamicColor(light: light, dark: dark)
            highlightColor = UIColor.dynamicColor(light: light_highlight, dark: dark_highlight)
            
            backgroundColor = color
        }
    }
    private var color: UIColor = .white
    private var highlightColor: UIColor = .white

    var bounceIntensity: BounceIntensity = .low
    var hapticsEnabled: Bool = true
    var circular: Bool = true {
        didSet {
            if circular != oldValue {
                layoutSubviews()
                updateConstraints()
            }
        }
    }
    
    private let hapticGenerator = UISelectionFeedbackGenerator()

    override init(frame: CGRect) {
        super.init(frame: .zero)

        adjustsImageWhenHighlighted = false
        backgroundColor = Constants.Color.shadedButtonBackgroundColor
        tintColor = Constants.Color.primary

        addTarget(
            self,
            action: #selector(touchDown),
            for: [.touchDown])
        addTarget(
            self,
            action: #selector(animateDown),
            for: [.touchDragEnter])
        addTarget(
            self,
            action: #selector(animateUp),
            for: [.touchDragExit, .touchCancel, .touchUpInside, .touchUpOutside])
    }
    init(tint: UIColor = Constants.Color.primary) {
        defer { self.tint = tint }
        super.init(frame: .zero)
    }
    
    private func updateRadius() {
        if circular {
            layer.cornerRadius = frame.width / 2
            layer.masksToBounds = true
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        if circular {
            updateRadius()
        }
    }

    override func updateConstraints() {
        super.updateConstraints()
        
        if circular {
            translatesAutoresizingMaskIntoConstraints = false
            widthAnchor.constraint(equalTo: heightAnchor).isActive = true
        }
    }

    @objc private func touchDown(sender: UIButton) {
        if hapticsEnabled {
            hapticGenerator.prepare()
            hapticGenerator.selectionChanged()
        }

        animateDown(sender: sender)
    }
    @objc private func animateDown(sender: UIButton) {
        UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: .allowUserInteraction, animations: {
            self.transform = CGAffineTransform.init(scaleX: 1.0 - self.bounceIntensity.rawValue / 50.0, y: 1.0 - self.bounceIntensity.rawValue / 50.0)
            self.backgroundColor = self.highlightColor
        }, completion: nil)
    }

    @objc private func animateUp(sender: UIButton) {
        delay(0.05) {
            UIView.animate(withDuration: 0.1) { self.backgroundColor = self.color }
        }
        UIView.animateKeyframes(withDuration: 0.25, delay: 0.0, options: [.allowUserInteraction, .calculationModeCubic, .beginFromCurrentState], animations: {
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.4) {
                self.transform = .init(scaleX: 1.0 + self.bounceIntensity.rawValue / 60.0, y: 1.0 + self.bounceIntensity.rawValue / 60.0)
            }

            UIView.addKeyframe(withRelativeStartTime: 0.4, relativeDuration: 0.6) {
                self.transform = .identity
            }
        }, completion: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

