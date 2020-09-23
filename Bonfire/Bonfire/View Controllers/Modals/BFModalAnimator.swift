//
//  BFModalAnimator.swift
//  Bonfire
//
//  Created by James Dale on 5/8/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit

final class BFModalAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    enum AnimationType {
        case presentation
        case dismissal
    }

    private let animationType: AnimationType

    init(type: AnimationType) {
        self.animationType = type
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?)
        -> TimeInterval
    {
        return 0.5
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: .from),
            let toVC = transitionContext.viewController(forKey: .to),
            let from = fromVC.view,
            let to = toVC.view
        else { return }
        let container = transitionContext.containerView

        let animator = UIViewPropertyAnimator(
            duration: 0,
            timingParameters: UISpringTimingParameters(dampingRatio: 1))

        animator.addAnimations { [weak self] in
            guard let self = self else { return }

            from.round(
                corners: [
                    .layerMaxXMaxYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner,
                    .layerMinXMinYCorner,
                ], radius: 38)
        }

        animator.startAnimation()
    }

}
