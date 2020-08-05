//
//  BFModalPresentationController.swift
//  Bonfire
//
//  Created by James Dale on 4/8/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit

final class BFModalPresentationController: UIPresentationController {
    
    private lazy var backingView: UIView! = {
        guard let container = containerView else { return nil }
        
        let view = UIView(frame: container.bounds)
        view.backgroundColor = .black
        
        return view
    }()
    
    override init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
    }
    
    func dismiss() {
        presentedViewController.dismiss(animated: true, completion: nil)
    }
    
    override var frameOfPresentedViewInContainerView: CGRect {
        guard let container = containerView else { return .zero }
        
        let barHeight: CGFloat
        if #available(iOS 13.0, *) {
            barHeight = container.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        } else {
            // TODO: Fix
            barHeight = 0
        }
        
        return CGRect(x: 0, y: barHeight, width: container.bounds.width, height: container.bounds.height - barHeight)
    }
    
    override func presentationTransitionWillBegin() {
        guard let container = containerView,
            let coordinator = presentingViewController.transitionCoordinator else { return }
        
        backingView.alpha = 0
        container.addSubview(backingView)
        backingView.addSubview(presentedViewController.view)
        
        coordinator.animate(alongsideTransition: { [weak self] context in
            guard let `self` = self else { return }
            
            self.backingView.alpha = 1
            self.presentedView?.layer.cornerRadius = 38
            self.presentedView?.layer.masksToBounds = true
            }, completion: nil)
    }
    
    override func dismissalTransitionWillBegin() {
        guard let coordinator = presentingViewController.transitionCoordinator else { return }
        
        coordinator.animate(alongsideTransition: { [weak self] (context) -> Void in
            guard let `self` = self else { return }
            
            self.backingView.alpha = 0
            self.presentedView?.layer.cornerRadius = 0
            }, completion: nil)
    }
    
    override func dismissalTransitionDidEnd(_ completed: Bool) {
        if completed {
            backingView.removeFromSuperview()
        }
    }
    
}
