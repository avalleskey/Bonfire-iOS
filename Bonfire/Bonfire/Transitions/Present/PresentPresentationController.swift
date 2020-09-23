//
//  PresentPresentationController.swift
//  Bonfire
//
//  Created by Daniel Gauthier on 2020-09-11.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Cartography
import UIKit

class PresentPresentationController: UIPresentationController {
    lazy var fadeView = UIView(backgroundColor: .darkFade, alpha: 0.0)

    override init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
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
        containerView.addSubview(fadeView)

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
        presentedView?.layer.cornerRadius = UIDevice.current.hasNotch ? UIDevice.current.cornerRadius : 16
        presentedView?.layer.masksToBounds = true
        if #available(iOS 13.0, *) {
            presentedView?.layer.cornerCurve = .continuous
        }
        presentedView?.applyShadow(intensity: .sketch(color: .black, alpha: 0.08, x: 0, y: -1, blur: 3, spread: 0))
    }

    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView = containerView else { return .zero }

        let top: CGFloat = UIApplication.shared.keyWindow?.safeAreaInsets.top ?? 0
        var rect = containerView.bounds
        rect.size.height -= top
        rect.origin.y = top
        
        return rect
    }
}
