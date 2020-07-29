//
//  KeyboardSubscriber.swift
//  Bonfire
//
//  Created by James Dale on 24/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit

class UIKeyboardSubscribedViewController: UIViewController {

    var keyboardConstraints: [NSLayoutConstraint] = []

    func subscribeToKeyboard() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(updateKeyboard(sender:)),
            name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(updateKeyboard(sender:)),
            name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    func unsubscribeToKeyboard() {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func updateKeyboard(sender: Notification) {
        guard let userInfo = sender.userInfo else { return }

        guard
            let keyboardHeight = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?
                .cgRectValue.height,
            let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
            let curve = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
        else { return }
        let isShowing = (sender.name == UIResponder.keyboardWillShowNotification)

        keyboardConstraints.forEach { $0.constant = isShowing ? -keyboardHeight : 0 }

        let options = UIView.AnimationOptions(rawValue: curve << 16)
        UIView.animate(
            withDuration: duration, delay: 0, options: options,
            animations: {
                self.view.layoutIfNeeded()
            },
            completion: nil
        )

    }
}
