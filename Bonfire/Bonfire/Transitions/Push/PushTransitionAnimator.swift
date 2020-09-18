//
//  PushTransitionAnimator.swift
//  Bonfire
//
//  Created by Austin Valleskey on 9/17/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit

class PushTransitionAnimator: NSObject {

    private let pushing: Bool
    lazy var fadeView = UIView(backgroundColor: .fade, alpha: 0.0)

    init(pushing: Bool) {
        self.pushing = pushing
        super.init()
    }
}

extension PushTransitionAnimator: UIViewControllerAnimatedTransitioning {

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        if pushing {
            return PushTransition.Constants.pushDuration
        } else {
            return PushTransition.Constants.popDuration
        }
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        if pushing {
            animatePushing(using: transitionContext)
        } else {
            animateDismissal(using: transitionContext)
        }
    }

    private func animatePushing(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        let presentingViewController = transitionContext.viewController(forKey: .from)!
        let presentedViewController = transitionContext.viewController(forKey: .to)!
        
        containerView.addSubview(fadeView)
        containerView.addSubview(presentedViewController.view)
        
        // styling presentedViewController
        presentedViewController.prepareViewControllerForPush()

        let presentedFrame = containerView.bounds
        let dismissedFrame = CGRect(x: presentedFrame.width * PushTransition.Constants.BottomView.xTranslationMultiplier, y: presentedFrame.minY, width: presentedFrame.width, height: presentedFrame.height)

        presentedViewController.view.frame = CGRect(x: presentedFrame.size.width, y: presentedFrame.minY, width: presentedFrame.size.width, height: presentedFrame.size.height)
        fadeView.frame = containerView.frame
        // this layout pass ensures that any intrinsic subview sizes are accurate before the presented view's frame is calculated
        presentedViewController.view.layoutIfNeeded()

        let animator = UIViewPropertyAnimator(duration: transitionDuration(using: transitionContext), dampingRatio: PushTransition.Constants.pushDamping) {
            self.fadeView.alpha = 1
            presentingViewController.view.frame = dismissedFrame
            presentedViewController.view.frame = presentedFrame
        }

        animator.addCompletion { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            presentedViewController.view.layer.cornerRadius = 0
        }

        animator.startAnimation()
    }

    private func animateDismissal(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        let presentingViewController = transitionContext.viewController(forKey: .to)!
        let presentedViewController = transitionContext.viewController(forKey: .from)!
        
        containerView.insertSubview(presentingViewController.view, belowSubview: presentedViewController.view)
        containerView.insertSubview(fadeView, belowSubview: presentedViewController.view)
                
        let presentedFrame = containerView.bounds
        let dismissedFrame = CGRect(x: presentedFrame.size.width, y: presentedFrame.minY, width: presentedFrame.width, height: presentedFrame.height)
        
        presentingViewController.view.frame = CGRect(x: presentedFrame.width * PushTransition.Constants.BottomView.xTranslationMultiplier, y: presentedFrame.minY, width: presentedFrame.width, height: presentedFrame.height)
        fadeView.frame = containerView.frame
        // this layout pass ensures that any intrinsic subview sizes are accurate before the presented view's frame is calculated
        presentingViewController.view.layoutSubviews()

        let animator = UIViewPropertyAnimator(duration: transitionDuration(using: transitionContext), dampingRatio: PushTransition.Constants.popDamping) {
            self.fadeView.alpha = 0
            presentingViewController.view.frame = presentedFrame
            presentedViewController.view.frame = dismissedFrame
        }

        animator.addCompletion { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            self.fadeView.removeFromSuperview()
        }

        animator.startAnimation()
    }
}
