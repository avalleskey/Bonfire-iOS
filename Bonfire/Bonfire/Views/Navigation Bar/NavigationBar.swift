//
//  NavigationBar.swift
//  Bonfire
//
//  Created by Daniel Gauthier on 2020-09-01.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit
import Cartography

protocol NavigationBarScrollHandling: UIScrollViewDelegate {
    var navigationBar: NavigationBar { get }

    func scrollViewDidScroll(_ scrollView: UIScrollView)
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView)
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView)
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>)
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool)
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView)
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool
    func scrollViewDidScrollToTop(_ scrollView: UIScrollView)
}

class NavigationBar: UIView {

    static let coreHeight: CGFloat = 62
    var height: CGFloat = coreHeight

    private let containerStackView = UIStackView(axis: .vertical, distribution: .fillProportionally, spacing: 0)
    
    private let pullTabView = UIView()
    private let contentView = UIView()
    
    private let leftButton = NavigationButton()
    private let rightButton = NavigationButton()
    private let centerButton = UIButton(width: 44, height: 44, cornerRadius: 22, systemButton: false)

    private let titleStackView = UIStackView(axis: .vertical, alignment: .center)
    private let titleLabel = UILabel(size: 20, weight: .heavy, multiline: false)
    private let subtitleLabel = UILabel(size: 12, weight: .bold, color: Constants.Color.secondary, multiline: false)

    private var elements: [UIView] {
        [leftButton, rightButton, centerButton, titleStackView]
    }

    private var hideOnScroll = true
    
    var leftButtonAction = {}
    var rightButtonAction = {}
    var centerButtonAction = {}
    
    var color: UIColor = Constants.Color.systemBackground {
        didSet {
            backgroundColor = color
            
            print("color: #\(color.toHex() ?? "")")
            
            var foreground: UIColor
            if color == Constants.Color.systemBackground {
                foreground = Constants.Color.primary
            } else {
                let darkBackground = color.isDarkColor
                foreground = darkBackground ? UIColor.white : UIColor.black
            }
            
            print("tint color: #\(foreground.toHex() ?? "")")
            
            leftButton.tint = foreground
            rightButton.tint = foreground
        }
    }

    private var scrollViewIsDecelerating = false
    private var scrollViewIsScrollingToTop = false
    private var navigationViewIsAnimating = false
    private var startingDragOffset: CGFloat = 0

    var topConstraint: NSLayoutConstraint?
    var contentViewHeightConstraint: NSLayoutConstraint?

    init(color: UIColor, leftButtonType: NavigationButtonType? = nil, rightButtonType: NavigationButtonType? = nil, titleImage: UIImage? = nil, title: String? = nil, subtitle: String? = nil, hideOnScroll: Bool? = true, showPullTab: Bool? = false) {
        defer {
            self.color = color
        }
        super.init(frame: .zero)

        self.hideOnScroll = hideOnScroll == true
        
        if showPullTab == true {
            setUpPullTabView()
        }
        setUpContentView()
        setUpContainerStackView()
        setUpLeftButton(type: leftButtonType)
        setUpCenterButton(image: titleImage)
        setUpRightButton(type: rightButtonType)
        setUpTitleStackView(title: title, subtitle: subtitle)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        applyShadow(intensity: .sketch(color: .black, alpha: 0, x: 0, y: 2, blur: 6, spread: 0))
    }

    private func setUpContainerStackView() {
        addSubview(containerStackView)
        constrain(containerStackView) {
            $0.width == $0.superview!.width
            $0.top == $0.superview!.safeAreaLayoutGuide.top
            $0.leading == $0.superview!.leading
            $0.trailing == $0.superview!.trailing
        }
        constrain(self, containerStackView) {
            $0.bottom == $1.bottom
        }
        
        let size = containerStackView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        height = size.height
        print("containerStackView height: \(height)")
    }
    
    private func setUpPullTabView() {
        containerStackView.addArrangedSubview(pullTabView)
        constrain(pullTabView) {
            $0.trailing == $0.superview!.trailing
            $0.leading == $0.superview!.leading
            $0.height == 14
        }
        
        let pullTabRectangle = UIView(backgroundColor: Constants.Color.borderColor, height: 5, width: 32, cornerRadius: 2.5)
        pullTabView.addSubview(pullTabRectangle)
        constrain(pullTabRectangle) {
            $0.centerX == $0.superview!.centerX
            $0.top == $0.superview!.top + 7
        }
    }
    
    private func setUpContentView() {
        containerStackView.addArrangedSubview(contentView)
        constrain(contentView) {
            $0.width == $0.superview!.width
            contentViewHeightConstraint = $0.height == NavigationBar.coreHeight
        }
    }
    
    private func setUpLeftButton(type: NavigationButtonType?) {
        contentView.addSubview(leftButton)
        constrain(leftButton) {
            $0.leading == $0.superview!.leading + 16
            $0.centerY == $0.superview!.centerY
            $0.width == 42
            $0.height == 42
        }

        if let type = type {
            leftButton.type = type
        } else {
            leftButton.isHidden = true
        }
        
        leftButton.addTarget(self, action: #selector(leftButtonTapped), for: .touchUpInside)
    }
    @objc private func leftButtonTapped() {
        leftButtonAction()
    }

    private func setUpCenterButton(image: UIImage?) {
        contentView.addSubview(centerButton)
        constrain(centerButton) {
            $0.centerX == $0.superview!.centerX
            $0.centerY == $0.superview!.centerY
        }

        if let image = image {
            centerButton.setImage(image, for: .normal)
        } else {
            centerButton.isHidden = true
        }

        centerButton.clipsToBounds = true
        centerButton.imageView?.contentMode = .scaleAspectFill
        
        centerButton.addTarget(self, action: #selector(centerButtonTapped), for: .touchUpInside)
    }
    @objc private func centerButtonTapped() {
        centerButtonAction()
    }

    private func setUpRightButton(type: NavigationButtonType?) {
        contentView.addSubview(rightButton)
        constrain(rightButton) {
            $0.trailing == $0.superview!.trailing - 16
            $0.centerY == $0.superview!.centerY
            $0.width == 42
            $0.height == 42
        }

        if let type = type {
            rightButton.type = type
        } else {
            rightButton.isHidden = true
        }
        
        rightButton.addTarget(self, action: #selector(rightButtonTapped), for: .touchUpInside)
    }
    @objc private func rightButtonTapped() {
        rightButtonAction()
    }

    private func setUpTitleStackView(title: String?, subtitle: String?) {
        contentView.addSubview(titleStackView)

        constrain(titleStackView, centerButton, leftButton, rightButton) {
            $0.center == $0.superview!.center
            $0.leading >= $2.trailing + 16 ~ .init(999)
            $0.trailing <= $3.leading - 16 ~ .init(999)
        }

        titleStackView.addArrangedSubview(titleLabel)
        titleStackView.addArrangedSubview(subtitleLabel)

        if let title = title {
            titleLabel.text = title
        } else {
            titleLabel.isHidden = true
        }

        if let subtitle = subtitle {
            subtitleLabel.text = subtitle
        } else {
            subtitleLabel.isHidden = true
        }

        titleStackView.isHidden = titleLabel.isHidden && subtitleLabel.isHidden
    }

    // MARK: - Scroll handling methods

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let shadowPercentage = Float(scrollView.contentOffset.y / self.height)
        layer.shadowOpacity = min(shadowPercentage * 0.08, 0.08)
        
        if !hideOnScroll { return }
        
        print("offset y: \(scrollView.contentOffset.y)")

        guard !navigationViewIsAnimating, let topConstraint = topConstraint else { return }
        
        let dragTranslation = startingDragOffset - scrollView.contentOffset.y
        if (dragTranslation < 0 || topConstraint.constant < 0) && scrollView.contentOffset.y < self.height {
            // start showing it gradually
            setTopConstraint(constant: -self.height + (self.height - scrollView.contentOffset.y))
        }
        
        if scrollView.contentOffset.y < 0 {
            self.contentViewHeightConstraint?.constant = NavigationBar.coreHeight + max(-scrollView.contentOffset.y, 0)
            self.superview?.layoutIfNeeded()
            print("constant == \(max(-scrollView.contentOffset.y, 0))")
        }
    }

    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        if !hideOnScroll { return }
        
        scrollViewIsDecelerating = true
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        scrollViewIsDecelerating = false
        scrollViewIsScrollingToTop = false
        startingDragOffset = scrollView.contentOffset.y
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if !hideOnScroll { return }
        
        if scrollView.panGestureRecognizer.velocity(in: scrollView).y < 0 && targetContentOffset.pointee.y > self.height {
            hideNavigationBar()
        } else if scrollView.panGestureRecognizer.velocity(in: scrollView).y > 0 && targetContentOffset.pointee.y >= self.height {
            showNavigationBar()
        } else if let topConstraint = topConstraint {
            if topConstraint.constant > -self.height && topConstraint.constant < 0 {
                let dragTranslation = startingDragOffset - scrollView.contentOffset.y
                if dragTranslation > 0 {
                    // going up
                    scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x, y: 0), animated: true)
                } else {
                    // going down
                    scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x, y: self.height), animated: true)
                }
            }
        }
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !hideOnScroll { return }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if !hideOnScroll { return }
        
        scrollViewIsDecelerating = false
    }

    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        scrollViewIsScrollingToTop = true
        showNavigationBar()
        return true
    }

    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        scrollViewIsScrollingToTop = false
    }

    func showNavigationBar() {
        navigationViewIsAnimating = true
        UIView.animate(withDuration: 0.35, delay: 0.0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.0, options: .allowUserInteraction, animations: {
            self.setTopConstraint(constant: 0)
            self.superview?.layoutIfNeeded()
        }, completion: { _ in
            self.navigationViewIsAnimating = false
        })

    }

    func hideNavigationBar() {
        navigationViewIsAnimating = true
        UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.0, options: .allowUserInteraction, animations: {
            self.setTopConstraint(constant: -self.height)
            self.superview?.layoutIfNeeded()
        }, completion: { _ in
            self.navigationViewIsAnimating = false
        })
    }

    private func setTopConstraint(constant: CGFloat) {
        self.topConstraint?.constant = constant
        let percentageComplete = constant / -self.height

        elements.forEach { $0.alpha = 1.0 - percentageComplete }
    }
}
