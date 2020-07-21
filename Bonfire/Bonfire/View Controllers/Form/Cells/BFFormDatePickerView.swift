//
//  BFFormDateView.swift
//  Bonfire
//
//  Created by James Dale on 21/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation
import UIKit

final class BFFormDatePickerView<FormData: BFFormData>: UIViewController, BFFormCell {

    let instructionLabel: UILabel = {
        let label = UILabel()
        label.text = "Enter text..."
        label.numberOfLines = 2
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium).rounded()
        label.textAlignment = .center
        return label
    }()

    let datePicker: UIDatePicker = {
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.backgroundColor = .white
        if #available(iOS 13.4, *) {
            datePicker.preferredDatePickerStyle = .wheels
        }
        return datePicker
    }()
    
    weak var delegate: BFFormTextViewDelegate?

    init(item: BFFormItem<FormData>) {
        super.init(nibName: nil, bundle: nil)

        view.addSubview(instructionLabel)
        view.addSubview(datePicker)
        
        instructionLabel.text = item.instructionText
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func value() -> BFFormItemValue {
        .date(datePicker.date)
    }

    override func updateViewConstraints() {
        super.updateViewConstraints()

        datePicker.translatesAutoresizingMaskIntoConstraints = false
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            datePicker.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            datePicker.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 24),
            datePicker.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -24),

            instructionLabel.centerYAnchor.constraint(equalTo: datePicker.centerYAnchor, constant: -(view.frame.size.height * 0.25)),

            instructionLabel.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 67),

            instructionLabel.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -67),
        ])
    }
}
