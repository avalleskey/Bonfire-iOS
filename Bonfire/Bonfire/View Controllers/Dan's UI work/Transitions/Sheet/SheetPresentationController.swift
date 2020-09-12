//
//  SheetPresentationController.swift
//  Bonfire
//
//  Created by Daniel Gauthier on 2020-09-11.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Cartography
import UIKit

class SheetPresentationController: UIPresentationController {
    lazy var fadeView = UIView(backgroundColor: .fade, alpha: 0.0)
    private var customHeight: CGFloat?

    init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?, tapToDismiss: Bool, customHeight: CGFloat? = nil) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        self.customHeight = customHeight

        if tapToDismiss {
            let dismissButton = UIButton()
            fadeView.addSubview(dismissButton)
            constrain(dismissButton) {
                $0.edges == $0.superview!.edges
            }
            dismissButton.addTarget(self, action: #selector(fadeViewTapped), for: .touchUpInside)
        }
    }

    @objc private func fadeViewTapped() {
        // if we have a transition coordinator, that means there is a transition already in progress;
        // calling dismiss in the middle of a dismissal (especially interactive) could break things.
        guard presentedViewController.transitionCoordinator == nil else { return }
        presentingViewController.dismiss(animated: true)
        (presentedViewController as? CustomPresentable)?.didDismissInteractively()
    }

    override func presentationTransitionWillBegin() {
        guard let containerView = containerView else { return }
        containerView.insertSubview(fadeView, at: 0)

        constrain(fadeView) {
            $0.edges == $0.superview!.edges
        }

        guard let coordinator = presentedViewController.transitionCoordinator else {
            fadeView.alpha = 1.0
            return
        }

        coordinator.animate(alongsideTransition: { _ in
            self.fadeView.alpha = 1.0
        })
    }

    override func dismissalTransitionWillBegin() {
        guard let coordinator = presentedViewController.transitionCoordinator else {
            fadeView.alpha = 0.0
            return
        }

        if !coordinator.isInteractive {
            coordinator.animate(alongsideTransition: { _ in
                self.fadeView.alpha = 0.0
            })
        }
    }

    override func containerViewWillLayoutSubviews() {
        presentedView?.frame = frameOfPresentedViewInContainerView
        presentedView?.layer.cornerRadius = 28
        presentedView?.applyShadow(intensity: .sketch(color: .black, alpha: 0.08, x: 0, y: -1, blur: 3, spread: 0))
    }

    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView = containerView else { return .zero }

        if let customHeight = customHeight {
            return CGRect(x: 0, y: containerView.bounds.height - customHeight, width: containerView.bounds.width, height: customHeight)
        } else {
            let topInset = containerView.safeAreaInsets.top + 32
            return CGRect(x: 0, y: topInset, width: containerView.bounds.width, height: containerView.bounds.height - topInset)
        }
    }
}
