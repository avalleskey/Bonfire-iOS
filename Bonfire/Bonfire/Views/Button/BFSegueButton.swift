//
//  BFSegueButton.swift
//  Bonfire
//
//  Created by James Dale on 20/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit

final class BFSegueButton: UIButton {

    init() {
        super.init(frame: .zero)
        backgroundColor = Constants.Color.brand
        layer.cornerRadius = 14
        titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold).rounded()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
