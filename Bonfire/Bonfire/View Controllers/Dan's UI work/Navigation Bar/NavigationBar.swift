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
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool)
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView)
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool
    func scrollViewDidScrollToTop(_ scrollView: UIScrollView)
}

class NavigationBar: UIView {

    static let coreHeight: CGFloat = 64

    private let leftButton = NavigationButton()
    private let rightButton = NavigationButton()
    private let centerButton = UIButton(width: 44, height: 44, cornerRadius: 22, systemButton: false)

    private let titleStackView = UIStackView(axis: .vertical, alignment: .center)
    private let titleLabel = UILabel(size: 18, weight: .bold, multiline: false)
    private let subtitleLabel = UILabel(size: 12, weight: .bold, color: .tertiaryLabel, multiline: false)

    private var elements: [UIView] {
        [leftButton, rightButton, centerButton, titleStackView]
    }

    var leftButtonAction = {}
    var rightButtonAction = {}
    var centerButtonAction = {}

    private var scrollViewIsDecelerating = false
    private var scrollViewIsScrollingToTop = false
    private var navigationViewIsAnimating = false
    private var startingDragOffset: CGFloat = 0

    var topConstraint: NSLayoutConstraint?

    init(color: UIColor, leftButtonType: NavigationButtonType? = nil, rightButtonType: NavigationButtonType? = nil, titleImage: UIImage? = nil, title: String? = nil, subtitle: String? = nil) {
        super.init(frame: .zero)
        backgroundColor = color

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

    private func setUpLeftButton(type: NavigationButtonType?) {
        addSubview(leftButton)
        constrain(leftButton) {
            $0.leading == $0.superview!.leading + 16
            $0.top == $0.superview!.safeAreaLayoutGuide.top + 10
            $0.bottom == $0.superview!.bottom - 10 ~ .init(999)
        }

        if let type = type {
            leftButton.type = type
        } else {
            leftButton.isHidden = true
        }
    }

    private func setUpCenterButton(image: UIImage?) {
        addSubview(centerButton)
        constrain(centerButton, leftButton) {
            $0.centerX == $0.superview!.centerX
            $0.centerY == $1.centerY
        }

        if let image = image {
            centerButton.setImage(image, for: .normal)
        } else {
            centerButton.isHidden = true
        }

        centerButton.clipsToBounds = true
        centerButton.imageView?.contentMode = .scaleAspectFill
    }

    private func setUpRightButton(type: NavigationButtonType?) {
        addSubview(rightButton)
        constrain(rightButton) {
            $0.trailing == $0.superview!.trailing - 16
            $0.top == $0.superview!.safeAreaLayoutGuide.top + 10
            $0.bottom == $0.superview!.bottom - 10 ~ .init(999)
        }

        if let type = type {
            rightButton.type = type
        } else {
            rightButton.isHidden = true
        }
    }

    private func setUpTitleStackView(title: String?, subtitle: String?) {
        addSubview(titleStackView)

        constrain(titleStackView, centerButton, leftButton, rightButton) {
            $0.center == $1.center
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

        let shadowPercentage = Float(scrollView.contentOffset.y / Self.coreHeight)
        layer.shadowOpacity = min(shadowPercentage * 0.08, 0.08)

        guard !scrollViewIsDecelerating, !scrollViewIsScrollingToTop, !navigationViewIsAnimating, let topConstraint = topConstraint else { return }

        let dragTranslation = startingDragOffset - scrollView.contentOffset.y
        if topConstraint.constant > -Self.coreHeight {
            setTopConstraint(constant: min(max(dragTranslation, -Self.coreHeight), 0))
        }
    }

    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        scrollViewIsDecelerating = true
        if scrollView.panGestureRecognizer.velocity(in: scrollView).y < 0 && scrollView.contentSize.height > scrollView.frame.height {
            hideNavigationBar()
        } else {
            showNavigationBar()
        }
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        scrollViewIsDecelerating = false
        scrollViewIsScrollingToTop = false
        startingDragOffset = scrollView.contentOffset.y
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate, let topConstraint = topConstraint {
            if topConstraint.constant < 0 && topConstraint.constant > -Self.coreHeight {
                if scrollView.contentOffset.y > Self.coreHeight {
                    hideNavigationBar()
                } else {
                    showNavigationBar()
                }
            }
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
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
        UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: .allowUserInteraction, animations: {
            self.setTopConstraint(constant: 0)
            self.superview?.layoutIfNeeded()
        }, completion: { _ in
            self.navigationViewIsAnimating = false
        })

    }

    func hideNavigationBar() {
        navigationViewIsAnimating = true
        UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: .allowUserInteraction, animations: {
            self.setTopConstraint(constant: -Self.coreHeight)
            self.superview?.layoutIfNeeded()
        }, completion: { _ in
            self.navigationViewIsAnimating = false
        })
    }

    private func setTopConstraint(constant: CGFloat) {
        self.topConstraint?.constant = constant
        let percentageComplete = constant / -Self.coreHeight

        elements.forEach { $0.alpha = 1.0 - percentageComplete }
    }
}
