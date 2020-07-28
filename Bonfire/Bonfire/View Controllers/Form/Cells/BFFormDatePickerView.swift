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

    let datePickerContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = Constants.Color.pillBackground
        
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.12
        view.layer.shadowOffset = .init(width: 0, height: 1)
        view.layer.shadowRadius = 2
        view.layer.cornerRadius = 14
        view.layer.shouldRasterize = true
        view.layer.rasterizationScale = UIScreen.main.scale
        view.layer.masksToBounds = false
        
        return view
    }()
    let datePicker: UIDatePicker = {
        let datePicker = UIDatePicker()
        if #available(iOS 13.4, *) {
            datePicker.preferredDatePickerStyle = .wheels
        }
        datePicker.datePickerMode = .date
        datePicker.backgroundColor = .clear
        
        return datePicker
    }()
    
    weak var delegate: BFFormTextViewDelegate?

    init(item: BFFormItem<FormData>) {
        super.init(nibName: nil, bundle: nil)

        view.addSubview(instructionLabel)
        datePickerContainerView.addSubview(datePicker)
        view.addSubview(datePickerContainerView)
        
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

        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        datePickerContainerView.translatesAutoresizingMaskIntoConstraints = false
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        
        var datePickerGutter: CGFloat = 0
        if #available(iOS 14.0, *) {
            datePickerGutter = 16
        }
        
        NSLayoutConstraint.activate([
            datePickerContainerView.heightAnchor.constraint(equalToConstant: 228),
            datePickerContainerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            datePickerContainerView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 24),
            datePickerContainerView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -24),
            
            datePicker.leadingAnchor.constraint(equalTo: datePickerContainerView.leadingAnchor, constant: datePickerGutter),
            datePicker.trailingAnchor.constraint(equalTo: datePickerContainerView.trailingAnchor, constant: -datePickerGutter),
            datePicker.heightAnchor.constraint(equalTo: datePickerContainerView.heightAnchor),

            instructionLabel.centerYAnchor.constraint(equalTo: datePicker.centerYAnchor, constant: -(view.frame.size.height * 0.25)),

            instructionLabel.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 24),

            instructionLabel.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -24),
        ])
    }
}
