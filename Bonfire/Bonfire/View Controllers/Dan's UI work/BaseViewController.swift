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

class BaseViewController: UIViewController {
    var navigationBar: NavigationBar

    init(navigationBar: NavigationBar, scrollView: UIScrollView) {
        self.navigationBar = navigationBar
        super.init(nibName: nil, bundle: nil)
        scrollView.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpNavigationBar()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.bringSubviewToFront(navigationBar)
    }

    private func setUpNavigationBar() {
        view.addSubview(navigationBar)
        constrain(navigationBar) {
            navigationBar.topConstraint = $0.top == $0.superview!.top
            $0.leading == $0.superview!.leading
            $0.trailing == $0.superview!.trailing
        }
    }
}

extension BaseViewController: NavigationBarScrollHandling {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        navigationBar.scrollViewDidScroll(scrollView)
    }

    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        navigationBar.scrollViewWillBeginDecelerating(scrollView)
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        navigationBar.scrollViewWillBeginDragging(scrollView)
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
