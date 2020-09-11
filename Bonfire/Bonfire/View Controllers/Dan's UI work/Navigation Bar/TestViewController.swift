//
//  TestViewController.swift
//  Bonfire
//
//  Created by Daniel Gauthier on 2020-09-01.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit
import Cartography

class TestViewController: UIViewController {

    private let button = UIButton(contentColor: .systemBlue, title: "Back", textFormat: (16, .bold), height: 36, systemButton: true)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .background

        view.addSubview(button)
        constrain(button) {
            $0.leading == $0.superview!.leading + 16
            $0.top == $0.superview!.safeAreaLayoutGuide.top + 16
        }

        button.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
    }

    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
}
