//
//  BFModalNavigationBar.swift
//  Bonfire
//
//  Created by James Dale on 4/8/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit

final class BFModalNavigationBar: UINavigationBar {

    let closeBtn: BFCircularButton = {
        let btn = BFCircularButton()
        btn.setImage(UIImage(named: "Close")?.withRenderingMode(.alwaysTemplate), for: .normal)
        btn.tintColor = Constants.Color.primary
        btn.backgroundColor = Constants.Color.secondaryFill
        return btn
    }()

    override init(frame: CGRect) {
        super.init(frame: .zero)

        let font = UIFont.systemFont(ofSize: 20, weight: .bold).rounded()
        titleTextAttributes = [NSAttributedString.Key.font: font]
        isTranslucent = true
        backgroundColor = .clear
        barTintColor = .clear
        shadowImage = nil

        if #available(iOS 13.0, *) {
            let navBarAppearance = UINavigationBarAppearance()
            navBarAppearance.configureWithOpaqueBackground()
            navBarAppearance.shadowColor = nil
            navBarAppearance.titleTextAttributes = [NSAttributedString.Key.font: font]
            standardAppearance = navBarAppearance
        }

        addSubview(closeBtn)

        updateConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateConstraints() {
        super.updateConstraints()

        closeBtn.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            closeBtn.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),
            closeBtn.centerYAnchor.constraint(equalTo: centerYAnchor),
            closeBtn.widthAnchor.constraint(equalToConstant: 40),
            closeBtn.heightAnchor.constraint(equalTo: closeBtn.widthAnchor),
        ])
    }
}
