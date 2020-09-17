//
//  CustomPresentable.swift
//  Bonfire
//
//  Created by Daniel Gauthier on 2020-09-11.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit

protocol CustomPresentable: UIViewController {
    var transitionManager: UIViewControllerTransitioningDelegate? { get set }
    var dismissalHandlingScrollView: UIScrollView? { get }

    func didDismissInteractively()
}

extension CustomPresentable {
    var dismissalHandlingScrollView: UIScrollView? { nil }
    func didDismissInteractively() {}
}
