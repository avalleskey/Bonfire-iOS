//
//  BaseViewController.swift
//  Bonfire
//
//  Created by Daniel Gauthier on 2020-09-04.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit
import Cartography

/*
 By subclassing BaseViewController, a view controller can easily install a navigation bar that automatically handles
 showing/hiding nav bar on scroll.

 All a subclass needs to do to get this behaviour for free is to pass a configured NavigationBar and the associated
 scroll view to BaseViewController on super.init.
 */

class BaseViewController: UIViewController, CustomPresentable {
    var navigationBar: NavigationBar
    var floatingButton: BFFloatingButton?
    
    // CustomPresentable
    var dismissalHandlingScrollView: UIScrollView?
    var transitionManager: UIViewControllerTransitioningDelegate?
    var interactionController: PushInteractionController?

    init(navigationBar: NavigationBar, scrollView: UIScrollView?, floatingButton: BFFloatingButton? = nil) {
        self.navigationBar = navigationBar
        self.floatingButton = floatingButton
        self.dismissalHandlingScrollView = scrollView
        super.init(nibName: nil, bundle: nil)
        
        if let scrollView = scrollView {
            scrollView.delegate = self
            updateTopOffset(scrollView: scrollView)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpNavigationBar()
        setUpFloatingButtonIfNeeded()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.bringSubviewToFront(navigationBar)
        if let btn = floatingButton {
            view.bringSubviewToFront(btn)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

    }
    
    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        
        // support custom push/pop transitions
        if let navigationController = self.navigationController {
            if navigationController.viewControllers.count > 1 {
                self.interactionController = PushInteractionController(viewController: self)
                self.navigationController?.delegate = self
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setNeedsStatusBarAppearanceUpdate()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.navigationController?.delegate = self
    }

    private func setUpNavigationBar() {
        view.addSubview(navigationBar)
        constrain(navigationBar) {
            navigationBar.topConstraint = $0.top == $0.superview!.top
            $0.leading == $0.superview!.leading
            $0.trailing == $0.superview!.trailing
        }
    }
    
    private func setUpFloatingButtonIfNeeded() {
        if let btn = floatingButton {
            view.addSubview(btn)
            constrain(btn) {
                $0.width == 64
                $0.height == $0.width
                $0.bottom == $0.superview!.safeAreaLayoutGuide.bottom - 12
                $0.right == $0.superview!.right - 12
            }
        }
    }
    
    public func dismissFloatingButtonIfNeeded(animated: Bool = true) {
        print("hide floating button")
        guard let button = floatingButton else { return }
        
        UIView.animate(withDuration: (animated ? 0.3 : 0), delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.0, options: .allowUserInteraction, animations: {
            button.alpha = 0
            button.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        }, completion: { _ in
            button.isUserInteractionEnabled = false
        })
    }
    public func showFloatingButtonIfNeeded(animated: Bool = true) {
        print("show floating button")
        guard let button = floatingButton else { return }
        
        button.isUserInteractionEnabled = true
        floatingButton?.iconImageView.alpha = 0
        floatingButton?.iconImageView.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
        UIView.animate(withDuration: (animated ? 0.35 :0), delay: 0.1, usingSpringWithDamping: 1, initialSpringVelocity: 0.0, options: .allowUserInteraction, animations: {
            self.floatingButton?.iconImageView.alpha = 1
            self.floatingButton?.iconImageView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }, completion: { _ in
            UIView.animate(withDuration: (animated ? 0.3 :0), delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.0, options: .allowUserInteraction, animations: {
                self.floatingButton?.iconImageView.transform = .identity
            }, completion: { _ in
                
            })
        })
    }
    
    private func updateTopOffset(scrollView: UIScrollView) {
        if scrollView is UITableView {
            (scrollView as! UITableView).tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: navigationBar.height))
        }
        scrollView.scrollIndicatorInsets = UIEdgeInsets(top: navigationBar.height + ((navigationBar.contentViewHeightConstraint?.constant ?? NavigationBar.coreHeight) - NavigationBar.coreHeight), left: 0, bottom: 0, right: 0)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        let darkBackground = navigationBar.backgroundColor?.isDarkColor ?? false
        return darkBackground ? .lightContent : .default
    }
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .fade
    }
}

extension BaseViewController: NavigationBarScrollHandling {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        navigationBar.scrollViewDidScroll(scrollView)
        
        updateTopOffset(scrollView: scrollView)
    }

    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        navigationBar.scrollViewWillBeginDecelerating(scrollView)
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        navigationBar.scrollViewWillBeginDragging(scrollView)
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        navigationBar.scrollViewWillEndDragging(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        navigationBar.scrollViewDidEndDragging(scrollView, willDecelerate: decelerate)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        navigationBar.scrollViewDidEndDecelerating(scrollView)
    }

    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        navigationBar.scrollViewShouldScrollToTop(scrollView)
    }

    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        navigationBar.scrollViewDidScrollToTop(scrollView)
    }
}

extension BaseViewController: UINavigationControllerDelegate {

    public func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        guard let interactionController = interactionController, interactionController.interactionInProgress else {
            return nil
        }
        return interactionController
    }
    public func navigationController(_ navigationController: UINavigationController,
                              animationControllerFor operation: UINavigationController.Operation,
                              from fromVC: UIViewController,
                              to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        switch operation {
        case .push:
            return PushTransitionAnimator(pushing: true)
        case .pop:
            return PushTransitionAnimator(pushing: false)
        default:
            return nil
        }
    }
}
