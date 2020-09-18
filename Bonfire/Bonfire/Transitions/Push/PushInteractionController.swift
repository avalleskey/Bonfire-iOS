//
//  PushInteractionController.swift
//  Bonfire
//
//  Created by Austin Valleskey on 9/17/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit

class PushInteractionController: NSObject, InteractionControlling {
    private(set) var interactionInProgress = false
    private var interactionIsFinishing = false
    private weak var viewController: CustomPresentable!
    private weak var transitionContext: UIViewControllerContextTransitioning?

    private var interactionDistance: CGFloat = 0
    private var interruptedTranslation: CGFloat = 0
    private var presentedFrame: CGRect?
    private var presentingFrame: CGRect?
    private var cancellationAnimator: UIViewPropertyAnimator?
    
    lazy var fadeView = UIView(backgroundColor: .fade, alpha: 0.0)

    // MARK: - Setup
    init(viewController: CustomPresentable) {
        self.viewController = viewController
        super.init()
        prepareGestureRecognizer(in: viewController.view)

        if let scrollView = viewController.dismissalHandlingScrollView {
            resolveScrollViewGestures(scrollView)
        }
        
        print("here we go. just set up a interaction controller for this view: \(viewController)")
    }

    private func prepareGestureRecognizer(in view: UIView) {
        let gesture = OneWayPanGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
        gesture.direction = .right
        view.addGestureRecognizer(gesture)
    }

    private func resolveScrollViewGestures(_ scrollView: UIScrollView) {
        let scrollGestureRecognizer = OneWayPanGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
        scrollGestureRecognizer.delegate = self

        scrollView.addGestureRecognizer(scrollGestureRecognizer)
        scrollView.panGestureRecognizer.require(toFail: scrollGestureRecognizer)
    }

    // MARK: - Gesture handling
    @objc func handleGesture(_ gestureRecognizer: OneWayPanGestureRecognizer) {
        guard let superview = gestureRecognizer.view?.superview, !interactionIsFinishing else { return }
        let translation = gestureRecognizer.translation(in: superview).x
        let velocity = gestureRecognizer.velocity(in: superview).x

        switch gestureRecognizer.state {
        case .began: gestureBegan()
        case .changed: gestureChanged(translation: translation + interruptedTranslation, velocity: velocity)
        case .cancelled: gestureCancelled(translation: translation + interruptedTranslation, velocity: velocity)
        case .ended: gestureEnded(translation: translation + interruptedTranslation, velocity: velocity)
        default: break
        }
    }

    private func gestureBegan() {
        disableOtherTouches()
        cancellationAnimator?.stopAnimation(true)

        if let presentedFrame = presentedFrame {
            interruptedTranslation = viewController.view.frame.minX - presentedFrame.minX
        }

        if !interactionInProgress {
            interactionInProgress = true
            viewController.prepareViewControllerForPush()
            viewController.navigationController?.popViewController(animated: true)
        }
    }

    private func gestureChanged(translation: CGFloat, velocity: CGFloat) {
        // the progress of the gesture is a percentage equal to translation / interaction distance.
        // we protect against a div/0 crash here by checking that interaction distance isn't 0.
        var progress = interactionDistance == 0 ? 0 : (translation / interactionDistance)

        // if the dismissal gesture is moving in the wrong direction, we allow for a bit of movement,
        // but progressively slow down how much progress can be made here to prevent the user
        // from being able to move the view all over the place.
        if progress < 0 { progress /= (1.0 + abs(progress * 20)) }
        update(progress: progress)
    }

    private func gestureCancelled(translation: CGFloat, velocity: CGFloat) {
        cancel(initialSpringVelocity: springVelocity(distanceToTravel: -translation, gestureVelocity: velocity))
    }

    private func gestureEnded(translation: CGFloat, velocity: CGFloat) {
        // check velocity and translation progress to determine whether the dismissal should be completed or cancelled.
        if velocity > 300 || (translation > interactionDistance / 2.0 && velocity > -300) {
            finish(initialSpringVelocity: springVelocity(distanceToTravel: interactionDistance - translation, gestureVelocity: velocity))
        } else {
            cancel(initialSpringVelocity: springVelocity(distanceToTravel: -translation, gestureVelocity: velocity))
        }
    }

    // MARK: - Transition controlling
    func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        guard
            let presentingViewController = transitionContext.viewController(forKey: .to),
            let presentedViewController = transitionContext.viewController(forKey: .from)
        else { return }
        
        let containerView = transitionContext.containerView
        
        containerView.insertSubview(presentingViewController.view, belowSubview: presentedViewController.view)
        containerView.insertSubview(fadeView, belowSubview: presentedViewController.view)
        
        presentedFrame = transitionContext.containerView.bounds
        presentingFrame = CGRect(x: transitionContext.containerView.bounds.width * PushTransition.Constants.BottomView.xTranslationMultiplier, y: transitionContext.containerView.bounds.minY, width: presentingViewController.view.frame.size.width, height: presentingViewController.view.frame.size.height)
        
        fadeView.frame = containerView.frame
        
        self.transitionContext = transitionContext
        interactionDistance = transitionContext.containerView.bounds.width - presentedViewController.view.frame.minX
        
        print("interactionDistance: \(interactionDistance)")
    }

    func update(progress: CGFloat) {
        guard
            let transitionContext = transitionContext,
            let presentedFrame = presentedFrame,
            let presentingFrame = presentingFrame,
            let presentingViewController = transitionContext.viewController(forKey: .to),
            let presentedViewController = transitionContext.viewController(forKey: .from)
        else { return }
        
        transitionContext.updateInteractiveTransition(progress)
        
        presentedViewController.view.frame = CGRect(x: presentedFrame.minX + interactionDistance * progress, y: presentedFrame.minY, width: presentedFrame.width, height: presentedFrame.height)
        presentingViewController.view.frame = CGRect(x: presentingFrame.minX - (interactionDistance * PushTransition.Constants.BottomView.xTranslationMultiplier) * progress, y: presentedFrame.minY, width: presentedFrame.width, height: presentedFrame.height)

        fadeView.alpha = 1.0 - progress
    }

    func cancel(initialSpringVelocity: CGFloat) {
        guard
            let transitionContext = transitionContext,
            let presentedFrame = presentedFrame,
            let presentingFrame = presentingFrame,
            let presentingViewController = transitionContext.viewController(forKey: .to),
            let presentedViewController = transitionContext.viewController(forKey: .from)
        else { return }

        let timingParameters = UISpringTimingParameters(dampingRatio: PushTransition.Constants.popDamping, initialVelocity: CGVector(dx: 0, dy: initialSpringVelocity))
        cancellationAnimator = UIViewPropertyAnimator(duration: PushTransition.Constants.popDuration, timingParameters: timingParameters)

        cancellationAnimator?.addAnimations {
            presentingViewController.view.frame = presentingFrame
            presentedViewController.view.frame = presentedFrame

            self.fadeView.alpha = 1.0
        }

        cancellationAnimator?.addCompletion { _ in
            transitionContext.cancelInteractiveTransition()
            transitionContext.completeTransition(false)
            self.interactionInProgress = false
            self.enableOtherTouches()
            
            presentingViewController.view.removeFromSuperview()
            self.fadeView.removeFromSuperview()
        }

        cancellationAnimator?.startAnimation()
    }

    func finish(initialSpringVelocity: CGFloat) {
        guard
            let transitionContext = transitionContext,
            let presentedFrame = presentedFrame,
            let presentingViewController = transitionContext.viewController(forKey: .to),
            let presentedViewController = transitionContext.viewController(forKey: .from)
        else { return }
        
        let dismissedFrame = CGRect(x: transitionContext.containerView.bounds.width, y: presentedFrame.minY, width: presentedFrame.width, height: presentedFrame.height)

        interactionIsFinishing = true

        let timingParameters = UISpringTimingParameters(dampingRatio: PushTransition.Constants.popDamping, initialVelocity: CGVector(dx: 0, dy: initialSpringVelocity))
        let finishAnimator = UIViewPropertyAnimator(duration: PushTransition.Constants.popDuration, timingParameters: timingParameters)

        finishAnimator.addAnimations {
            presentingViewController.view.frame = presentedFrame
            presentedViewController.view.frame = dismissedFrame

            self.fadeView.alpha = 0.0
        }

        finishAnimator.addCompletion { _ in
            transitionContext.finishInteractiveTransition()
            transitionContext.completeTransition(true)
            self.interactionInProgress = false
            self.fadeView.removeFromSuperview()
        }

        finishAnimator.startAnimation()
    }

    // MARK: - Helpers
    private func springVelocity(distanceToTravel: CGFloat, gestureVelocity: CGFloat) -> CGFloat {
        distanceToTravel == 0 ? 0 : gestureVelocity / distanceToTravel
    }

    private func disableOtherTouches() {
        viewController.view.endEditing(true)
        viewController.view.subviews.forEach {
            $0.isUserInteractionEnabled = false
        }
    }

    private func enableOtherTouches() {
        viewController.view.subviews.forEach {
            $0.isUserInteractionEnabled = true
        }
    }
}

// This func enables the following behaviour:
// If the scroll view is scrolled to the top, and a swipe gesture is detected, activate dismissal swipe gesture.
// If scroll view isn't at the top, and a swipe gesture is detected, activate scroll view swipe gesture.
extension PushInteractionController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let scrollView = viewController.dismissalHandlingScrollView {
            return scrollView.contentOffset.x <= 0
        }
        return true
    }
}
