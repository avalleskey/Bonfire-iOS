//
//  UIViewController+Extensions.swift
//  Bonfire
//
//  Created by James Dale on 22/6/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit

// default nav item extensions to come
extension UIViewController {
    func scrollToTop() {
        func scrollToTop(view: UIView?) {
            guard let view = view else { return }

            switch view {
            case let scrollView as UIScrollView:
                if scrollView.scrollsToTop {
                    scrollView.setContentOffset(CGPoint(x: 0.0, y: -scrollView.contentInset.top), animated: true)
                    return
                }
            default:
                break
            }

            for subView in view.subviews {
                scrollToTop(view: subView)
            }
        }

        scrollToTop(view: self.view)

        if let navigationController = self as? UINavigationController {
            (navigationController.topViewController as? Navigating)?.navigationView.showNavigationView()
        } else {
            (self as? Navigating)?.navigationView.showNavigationView()
        }
    }
}
