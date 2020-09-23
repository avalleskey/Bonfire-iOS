//
//  BFModalTransitioningDelegate.swift
//  Bonfire
//
//  Created by James Dale on 4/8/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit

final class BFModalTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {

    init(from presented: UIViewController, to presenting: UIViewController) {
        super.init()
    }

    func presentationController(
        forPresented presented: UIViewController, presenting: UIViewController?,
        source: UIViewController
    ) -> UIPresentationController? {
        return BFModalPresentationController(
            presentedViewController: presented,
            presenting: presenting)
    }

    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning)
        -> UIViewControllerInteractiveTransitioning?
    {
        return nil
    }

}
