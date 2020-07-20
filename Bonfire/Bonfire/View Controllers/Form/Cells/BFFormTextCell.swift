//
//  BFFormTextCell.swift
//  Bonfire
//
//  Created by James Dale on 18/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation
import UIKit

final class BFFormTextView<FormData: BFFormData>: UIViewController, BFFormCell {

    let instructionLabel: UILabel = {
        let label = UILabel()
        label.text = "Enter text..."
        label.numberOfLines = 2
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium).rounded()
        label.textAlignment = .center
        return label
    }()

    let textField: BFTextField = {
        let textField = BFTextField()
        textField.placeholder = "Enter Value..."
        return textField
    }()

    init(item: BFFormItem<FormData>) {
        super.init(nibName: nil, bundle: nil)

        view.addSubview(instructionLabel)
        view.addSubview(textField)
        
        instructionLabel.text = item.instructionText
        textField.placeholder = item.placeholderText
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func value() -> BFFormItemValue {
        .string(textField.text ?? "")
    }

    override func updateViewConstraints() {
        super.updateViewConstraints()

        textField.translatesAutoresizingMaskIntoConstraints = false
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            textField.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            textField.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 24),
            textField.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -24),

            instructionLabel.bottomAnchor.constraint(
                equalTo: textField.topAnchor,
                constant: -80),

            instructionLabel.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 67),

            instructionLabel.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -67),
        ])
    }
}
