//
//  BFFormViewController.swift
//  Bonfire
//
//  Created by James Dale on 18/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation
import UIKit

final class BFFormViewController<Form: BFForm>: UIViewController {

    private let pageViewController: BFFormPageViewController

    private let form: Form

    private var currentItem: BFFormItem<Form.DataType>?
    private var currentCell: BFFormCell?

    private let nextBtn: UIButton = {
        let btn = BFSegueButton()
        btn.setTitle("Next", for: .normal)
        btn.addTarget(self, action: #selector(nextBtnTap(sender:)), for: .touchUpInside)
        return btn
    }()

    init(form: Form) {
        self.form = form
        self.currentItem = form.items.first
        pageViewController = BFFormPageViewController()
        
        super.init(nibName: nil, bundle: nil)
        view.backgroundColor = Constants.Color.systemBackground
        view.addSubview(pageViewController.view)
        if let item = self.currentItem, let initialVC = viewControllerForInput(input: item) {
            pageViewController.setInitialViewController(initialVC)
            currentCell = initialVC
        }
        view.addSubview(nextBtn)
        updateViewConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateViewConstraints() {
        super.updateViewConstraints()

        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        nextBtn.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            pageViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            pageViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            pageViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            nextBtn.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                constant: -20),
            nextBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            nextBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            nextBtn.heightAnchor.constraint(equalToConstant: 48),
        ])
    }

    @objc private func nextBtnTap(sender: UIButton) {
        guard let currentIdx = form.items.firstIndex(where: { $0 == currentItem }),
              let currentCell = currentCell else { return }

        let value = currentCell.value()
        if currentItem?.validate(value) ?? false {
            if let updatePath = currentItem?.path {
                form.data.set(value: value, forKeyPath: updatePath)
            }
            let nextIdx = form.items.index(after: currentIdx)
            guard nextIdx < form.items.endIndex else {
                form.finalize { (success) in
                    if success {
                        self.dismiss(animated: true)
                    }
                }
                return
            }
            let nextItem = form.items[nextIdx]
            currentItem = nextItem
            guard let nextVC = viewControllerForInput(input: nextItem) else { return }
            self.currentCell = nextVC
            pageViewController.segue(
                to: nextVC,
                direction: .right)
        }
    }

    private func viewControllerForInput(input: BFFormItem<Form.DataType>?)
        -> BFFormCell?
    {
        guard let input = input else { return nil }
        switch input.type {
        case .text, .password, .email, .otp:
            let textView = BFFormTextView<Form.DataType>(item: input)
            textView.delegate = self
            return textView
        case .date:
            let datePickerView = BFFormDatePickerView<Form.DataType>(item: input)
            datePickerView.datePicker.datePickerMode = .date
            return datePickerView
        case .image:
            return BFFormImagePickerView<Form.DataType>(item: input)
        case .color:
            return BFFormColorPickerView<Form.DataType>(item: input)
        default:
            fatalError("Unsupported form type \(input.type)")
        }
    }

}

extension BFFormViewController: BFFormTextViewDelegate {
    func next() {
        nextBtnTap(sender: nextBtn)
    }
}
