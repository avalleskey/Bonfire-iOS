//
//  UIViewController+Transitions.swift
//  Bonfire
//
//  Created by Daniel Gauthier on 2020-09-11.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit

enum CustomPresentationType {
    case sheet(customHeight: CGFloat? = nil)
    case present
}

extension UIViewController {
    func present(_ viewController: CustomPresentable, customPresentationType: CustomPresentationType, tapToDismiss: Bool = false, completion: (() -> Void)? = nil) {

        var interactionController: InteractionControlling?
        switch customPresentationType {
            case .sheet:
                interactionController = SheetInteractionController(viewController: viewController)
            case .present:
                interactionController = PresentInteractionController(viewController: viewController)
        }

        let transitionManager = ModalTransitionManager(customPresentationType: customPresentationType, interactionController: interactionController, tapToDismiss: tapToDismiss)
        viewController.transitionManager = transitionManager
        viewController.transitioningDelegate = transitionManager
        viewController.modalPresentationStyle = .custom
        present(viewController, animated: true, completion: completion)
    }
}
