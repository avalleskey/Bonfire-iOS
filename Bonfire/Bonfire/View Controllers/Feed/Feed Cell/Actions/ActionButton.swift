//
//  ActionButton.swift
//  Bonfire
//
//  Created by Daniel Gauthier on 2020-08-19.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit
import Cartography

class FeedCellActionButton: UIControl {

    private enum TouchState {
        case down
        case up
        case cancelled
    }

    enum BounceIntensity: CGFloat {
        case normal = 5.0
        case low = 2.0
        case none = 0.0
    }

    var bounceIntensity: BounceIntensity = .low
    var hapticsEnabled: Bool = true
    var selectable: Bool = false

    private let hapticGenerator = UISelectionFeedbackGenerator()

    private var touchState: TouchState = .up {
        didSet {
            guard touchState != oldValue else { return }

            switch touchState {
            case .down:
                if hapticsEnabled { hapticGenerator.prepare() }
                
                if !isSelected {
                    layer.borderColor = self.color.withAlphaComponent(0.5).cgColor
                    backgroundColor = self.color.withAlphaComponent(0.05)
                }
                
                
                UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: .allowUserInteraction, animations: {
                    self.transform = CGAffineTransform.init(scaleX: 1.0 - self.bounceIntensity.rawValue / 50.0, y: 1.0 - self.bounceIntensity.rawValue / 50.0)
                }, completion: nil)
            case .up:
                if hapticsEnabled {
                    hapticGenerator.selectionChanged()
                }

                if selectable {
                    self.setSelected(!isSelected, animated: true)
                } else {
                    delay(0.05) {
                        self.animateBorderColor(toColor: Constants.Color.primary.withAlphaComponent(0.04), duration: 0.1)
                        UIView.animate(withDuration: 0.1) { self.backgroundColor = .background }
                    }
                }
                UIView.animateKeyframes(withDuration: 0.25, delay: 0.0, options: [.allowUserInteraction, .calculationModeCubic, .beginFromCurrentState], animations: {
                    UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.4) {
                        self.transform = .init(scaleX: 1.0 + self.bounceIntensity.rawValue / 60.0, y: 1.0 + self.bounceIntensity.rawValue / 60.0)
                    }

                    UIView.addKeyframe(withRelativeStartTime: 0.4, relativeDuration: 0.6) {
                        self.transform = .identity
                    }
                }, completion: nil)
            case .cancelled:
                animateBorderColor(toColor: Constants.Color.primary.withAlphaComponent(0.04), duration: 0.1)
                UIView.animate(withDuration: 0.1) { self.backgroundColor = .background }
                UIView.animate(withDuration: 0.25, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: .allowUserInteraction, animations: {
                    self.transform = .identity
                }, completion: nil)
            }
        }
    }

    private let stackView = UIStackView(axis: .horizontal, alignment: .center, spacing: 4)
    private let label = UILabel(size: 14, weight: .bold)
    private var imageView = UIImageView(width: 15, height: 15, contentMode: .center)

    private var homeBounds: CGRect!
    private var dragBounds: CGRect { CGRect(x: touchBounds.origin.x - 24, y: touchBounds.origin.y - 24, width: touchBounds.size.width + 48, height: touchBounds.size.height + 48) }
    private var touchBounds: CGRect { bounds.insetBy(dx: min(-((40 - bounds.width) / 2), 0), dy: min(-((40 - bounds.height) / 2), 0)) }

    var color: UIColor = .text {
        didSet {
            buttonStateUpdated()
        }
    }

    var title: String? = nil {
        didSet {
            buttonStateUpdated()
        }
    }
    
    var selectedTitle: String? = nil

    var image: UIImage? = nil {
        didSet {
            imageView.isHidden = image == nil
            imageView.image = image
        }
    }

    override var isSelected: Bool {
        didSet {
            print("isSelected? \(isSelected ? "YES" : "NO")")
            buttonStateUpdated()
        }
    }
    func setSelected(_ selected: Bool, animated: Bool = false) {
        UIView.animate(withDuration: (animated ? 0.3 : 0), delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.5, options: .allowUserInteraction) {
            self.isSelected = selected
        } completion: { finished in
            
        }

        if selected {
            self.animateBorderColor(toColor: .clear, duration: (animated ? 0.3 : 0))
        } else {
            self.animateBorderColor(toColor: Constants.Color.primary.withAlphaComponent(0.04), duration: (animated ? 0.3 : 0))
        }
    }
    
    private func buttonStateUpdated() {
        if isSelected {
            label.text = selectedTitle ?? title
            backgroundColor = color
            
            let foreground = color.isDarkColor ? UIColor.white : UIColor.black
            label.textColor = foreground
            imageView.tintColor = foreground
        } else {
            label.text = title
            backgroundColor = .clear
            label.textColor = color
            imageView.tintColor = color
        }
        label.isHidden = label.text == nil
    }

    init(title: String? = nil, image: UIImage? = nil, color: UIColor = .text) {
        super.init(frame: .zero)
        setUpView()
        setUpContent()

        defer {
            self.title = title
            self.image = image
            self.color = color
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpView() {
        constrain(self) {
            $0.height == 36
            $0.width >= $0.height
        }
        layer.cornerRadius = 18
        if #available(iOS 13.0, *) { layer.cornerCurve = .continuous }
        layer.borderWidth = 2.0
        layer.borderColor = Constants.Color.primary.withAlphaComponent(0.04).cgColor
    }

    private func setUpContent() {
        stackView.isUserInteractionEnabled = false
        addSubview(stackView)
        constrain(stackView) {
            $0.edges == inset($0.superview!.edges, 12, 4)
        }

        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(label)

        label.numberOfLines = 1
    }

    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        homeBounds = dragBounds
        touchState = .down
        return true
    }

    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let point = touch.location(in: self)
        if homeBounds.contains(point) {
            touchState = .down
        } else {
            touchState = .cancelled
            return false
        }
        return true
    }

    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        super.endTracking(touch, with: event)
        if let point = touch?.location(in: self), homeBounds.contains(point) {
            // This negligible delay ensures that the button text/size is updated before the touch up animation starts
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.005) {
                self.touchState = .up
            }
        } else {
            touchState = .cancelled
        }
    }

    override func cancelTracking(with event: UIEvent?) {
        super.cancelTracking(with: event)
        touchState = .cancelled
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool { touchBounds.contains(point) }
}


extension UIView {
  func animateBorderColor(toColor: UIColor, duration: Double) {
    let animation: CABasicAnimation = CABasicAnimation(keyPath: "borderColor")
    animation.fromValue = layer.borderColor
    animation.toValue = toColor.cgColor
    animation.duration = duration
    layer.add(animation, forKey: "borderColor")
    layer.borderColor = toColor.cgColor
  }
}

func delay(_ delay: TimeInterval, closure: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: closure)
}
