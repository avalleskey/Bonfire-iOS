//
//  CustomTransitionManager.swift
//  Bonfire
//
//  Created by Daniel Gauthier on 2020-09-11.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit

class ModalTransitionManager: NSObject {

    private var customPresentationType: CustomPresentationType
    private var interactionController: InteractionControlling?
    private var tapToDismiss: Bool

    init(customPresentationType: CustomPresentationType, interactionController: InteractionControlling?, tapToDismiss: Bool) {
        self.customPresentationType = customPresentationType
        self.interactionController = interactionController
        self.tapToDismiss = tapToDismiss
    }
}

extension ModalTransitionManager: UIViewControllerTransitioningDelegate {

    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        switch customPresentationType {
            case .sheet(let customHeight):
                return SheetPresentationController(presentedViewController: presented, presenting: presenting, tapToDismiss: tapToDismiss, customHeight: customHeight)
            case .present:
                return PresentPresentationController(presentedViewController: presented, presenting: presenting)
        }
    }

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        switch customPresentationType {
            case .sheet:
                return SheetTransitionAnimator(presenting: true)
            case .present:
                return PresentTransitionAnimator(presenting: true)
        }
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        switch customPresentationType {
            case .sheet:
                return SheetTransitionAnimator(presenting: false)
            case .present:
                return PresentTransitionAnimator(presenting: false)
            
        }
    }

    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        guard let interactionController = interactionController, interactionController.interactionInProgress else {
            return nil
        }
        return interactionController
    }
}
