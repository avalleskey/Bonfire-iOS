//
//  BFModalNavigationController.swift
//  Bonfire
//
//  Created by James Dale on 5/8/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit

final class BFModalNavigationController: UINavigationController {

    init(root: UIViewController) {
        super.init(navigationBarClass: BFModalNavigationBar.self, toolbarClass: nil)
        pushViewController(root, animated: false)

        if let bfNavigationBar = navigationBar as? BFModalNavigationBar {
            bfNavigationBar.closeBtn.addTarget(
                self,
                action: #selector(closeBtnTap),
                for: .touchUpInside)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func closeBtnTap() {
        dismiss(animated: true)
    }
}
