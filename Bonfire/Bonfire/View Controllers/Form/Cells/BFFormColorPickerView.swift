//
//  BFFormColorPickerView.swift
//  Bonfire
//
//  Created by James Dale on 21/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit

final class BFFormColorPickerView<FormData: BFFormData>: UIViewController, BFFormCell {

    let instructionLabel: UILabel = {
        let label = UILabel()
        label.text = "Enter text..."
        label.numberOfLines = 2
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium).rounded()
        label.textAlignment = .center
        return label
    }()
    
    private var selectedColor: UIColor?

    let colorPickerView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        
        let blueBtn = BFColorPickerButton(color: .systemBlue)
        let purpleBtn = BFColorPickerButton(color: .systemPurple)
        let pinkBtn = BFColorPickerButton(color: .systemPink)
        let row1StackView = UIStackView(arrangedSubviews: [blueBtn, purpleBtn, pinkBtn])
        
        let orangeBtn = BFColorPickerButton(color: .systemOrange)
        let yellowBtn = BFColorPickerButton(color: .systemYellow)
        let greenBtn = BFColorPickerButton(color: .systemGreen)
        let row2StackView = UIStackView(arrangedSubviews: [orangeBtn, yellowBtn, greenBtn])
        
        let magentaBtn = BFColorPickerButton(color: .magenta)
        let tealBtn = BFColorPickerButton(color: .systemTeal)
        let grayBtn = BFColorPickerButton(color: .systemGray)
        let row3StackView = UIStackView(arrangedSubviews: [magentaBtn, tealBtn, grayBtn])
        
        stackView.addArrangedSubview(row1StackView)
        stackView.addArrangedSubview(row2StackView)
        stackView.addArrangedSubview(row3StackView)
        
        for case let rowSubview as UIStackView in stackView.arrangedSubviews {
            rowSubview.distribution = .fillEqually
            rowSubview.spacing = 24
            for case let columnSubview as UIStackView in rowSubview.arrangedSubviews {
                columnSubview.distribution = .fillEqually
                columnSubview.spacing = 24
            }
        }
        
        return stackView
    }()
    
    weak var delegate: BFFormTextViewDelegate?

    init(item: BFFormItem<FormData>) {
        super.init(nibName: nil, bundle: nil)

        view.addSubview(instructionLabel)
        view.addSubview(colorPickerView)
        
        instructionLabel.text = item.instructionText
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func value() -> BFFormItemValue {
        .data(Data())
    }
    
    @objc private func imageBtnTap(sender: UIButton) {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true)
    }

    override func updateViewConstraints() {
        super.updateViewConstraints()

        colorPickerView.translatesAutoresizingMaskIntoConstraints = false
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            colorPickerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            colorPickerView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 24),
            colorPickerView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -24),

            instructionLabel.centerYAnchor.constraint(equalTo: colorPickerView.centerYAnchor, constant: -(view.frame.size.height * 0.25)),

            instructionLabel.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 24),

            instructionLabel.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -24),
        ])
    }
}
