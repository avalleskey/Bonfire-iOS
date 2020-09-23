//
//  BFFloatingButton.swift
//  Bonfire
//
//  Created by Austin Valleskey on 9/15/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit
import Cartography

protocol BFFloatingButtonDelegate: AnyObject {
    func floatingButtonTapped()
}

enum BFFloatingButtonBackground {
    case color(_ color: UIColor? = Constants.Color.secondary)
    case image(_ image: UIImage? = UIImage())
}

class BFFloatingButton: UIControl {

    weak var delegate: BFFloatingButtonDelegate?
    
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

    var bounceIntensity: BounceIntensity = .normal
    var hapticsEnabled: Bool = true

    private let hapticGenerator = UISelectionFeedbackGenerator()

    private var touchState: TouchState = .up {
        didSet {
            guard touchState != oldValue else { return }

            switch touchState {
            case .down:
                if hapticsEnabled { hapticGenerator.prepare() }
                UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: .allowUserInteraction, animations: {
                    self.transform = CGAffineTransform.init(scaleX: 1.0 - self.bounceIntensity.rawValue / 50.0, y: 1.0 - self.bounceIntensity.rawValue / 50.0)
                }, completion: nil)
            case .up:
                if hapticsEnabled {
                    hapticGenerator.selectionChanged()
                }
                
                delegate?.floatingButtonTapped()

                UIView.animateKeyframes(withDuration: 0.25, delay: 0.0, options: [.allowUserInteraction, .calculationModeCubic, .beginFromCurrentState], animations: {
                    UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.4) {
                        self.transform = .init(scaleX: 1.0 + self.bounceIntensity.rawValue / 60.0, y: 1.0 + self.bounceIntensity.rawValue / 60.0)
                    }

                    UIView.addKeyframe(withRelativeStartTime: 0.4, relativeDuration: 0.6) {
                        self.transform = .identity
                    }
                }, completion: nil)
            case .cancelled:
                UIView.animate(withDuration: 0.25, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: .allowUserInteraction, animations: {
                    self.transform = .identity
                }, completion: nil)
            }
        }
    }

    public var iconImageView = UIImageView(width: 42, height: 42, contentMode: .center)
    private var backgroundImageView = UIImageView(contentMode: .scaleAspectFill)
    private var backgroundImageViewShadow = UIView()
    private var backgroundImageViewShadowImageView = UIImageView(contentMode: .scaleAspectFill)

    private var homeBounds: CGRect!
    private var dragBounds: CGRect { CGRect(x: touchBounds.origin.x - 24, y: touchBounds.origin.y - 24, width: touchBounds.size.width + 48, height: touchBounds.size.height + 48) }
    private var touchBounds: CGRect { bounds.insetBy(dx: min(-((40 - bounds.width) / 2), 0), dy: min(-((40 - bounds.height) / 2), 0)) }
    
    var color: UIColor? = nil {
        didSet {
            backgroundColor = color
        }
    }
    
    var icon: UIImage? = nil {
        didSet {
            iconImageView.isHidden = icon == nil
            iconImageView.image = icon
        }
    }
    
    var background: BFFloatingButtonBackground? {
        didSet {
            switch background {
                case .color(let color):
                    backgroundColor = color
                    backgroundImageView.isHidden = true
                    backgroundImageView.image = nil
                case .image(let image):
                    backgroundColor = .clear
                    backgroundImageView.isHidden = false
                    backgroundImageView.image = image
                case .none:
                    break
            }
        }
    }

    init(icon: UIImage? = nil, background: BFFloatingButtonBackground? = .image(UIImage(named: "FloatingButtonGradientBackground"))) {
        super.init(frame: .zero)
        setUpView()
        setUpContent()

        defer {
            self.icon = icon
            self.background = background
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpView() {
        layer.masksToBounds = false
        tintColor = .white
        
        applyShadow(intensity: .sketch(color: .black, alpha: 0.12, x: 0, y: 2, blur: 6, spread: 0))
    }

    private func setUpContent() {
        backgroundImageViewShadowImageView.layer.cornerRadius = layer.cornerRadius
        backgroundImageViewShadowImageView.layer.masksToBounds = true
        backgroundImageViewShadow.addSubview(backgroundImageViewShadowImageView)
        
        backgroundImageViewShadow.alpha = 0.2
        backgroundImageViewShadow.layer.zPosition = 1
        insertSubview(backgroundImageViewShadow, at: 0)
        constrain(backgroundImageViewShadow, backgroundImageViewShadowImageView) {
            $0.width == $0.superview!.width + 48
            $0.height == $0.superview!.height + 48
            
            $0.centerX == $0.superview!.centerX
            $0.centerY == $0.superview!.centerY + 4
            
            $1.width == $0.superview!.width
            $1.height == $1.width
            $1.center == $0.center
        }
        
        backgroundImageView.layer.cornerRadius = layer.cornerRadius
        backgroundImageView.layer.masksToBounds = true
        backgroundImageView.layer.zPosition = 2
        addSubview(backgroundImageView)
        constrain(backgroundImageView) {
            $0.edges == $0.superview!.edges
        }
        
        iconImageView.layer.zPosition = 3
        addSubview(iconImageView)
        constrain(iconImageView) {
            $0.center == $0.superview!.center
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = frame.width / 2
        backgroundImageView.layer.cornerRadius = layer.cornerRadius
        backgroundImageViewShadowImageView.layer.cornerRadius = layer.cornerRadius
        
        backgroundImageViewShadow.blur(radius: 6)
        backgroundImageViewShadow.superview?.sendSubviewToBack(backgroundImageViewShadow)
    }
    
    override func updateConstraints() {
        super.updateConstraints()
        
        translatesAutoresizingMaskIntoConstraints = false
        widthAnchor.constraint(equalTo: heightAnchor).isActive = true
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

