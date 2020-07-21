//
//  BFFormImagePickerView.swift
//  Bonfire
//
//  Created by James Dale on 21/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit

final class BFFormImagePickerView<FormData: BFFormData>: UIViewController, BFFormCell {

    let instructionLabel: UILabel = {
        let label = UILabel()
        label.text = "Enter text..."
        label.numberOfLines = 2
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium).rounded()
        label.textAlignment = .center
        return label
    }()

    let imagePickerBtn: UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage(named: "UploadImage"), for: .normal)
        btn.addTarget(self,
                      action: #selector(imageBtnTap(sender:)),
                      for: .touchUpInside)
        return btn
    }()
    
    weak var delegate: BFFormTextViewDelegate?

    init(item: BFFormItem<FormData>) {
        super.init(nibName: nil, bundle: nil)

        view.addSubview(instructionLabel)
        view.addSubview(imagePickerBtn)
        
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

        imagePickerBtn.translatesAutoresizingMaskIntoConstraints = false
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            imagePickerBtn.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            imagePickerBtn.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 24),
            imagePickerBtn.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -24),

            instructionLabel.centerYAnchor.constraint(equalTo: imagePickerBtn.centerYAnchor, constant: -(view.frame.size.height * 0.25)),

            instructionLabel.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 67),

            instructionLabel.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -67),
        ])
    }
}
