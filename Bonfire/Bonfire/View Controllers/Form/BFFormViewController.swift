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
        let initialVC = Self.viewControllerForInput(input: self.currentItem)
        pageViewController = BFFormPageViewController(initialVC: initialVC)
        currentCell = initialVC
        super.init(nibName: nil, bundle: nil)
        view.backgroundColor = .white
        view.addSubview(pageViewController.view)

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
        let nextIdx = form.items.index(after: currentIdx)
        let nextItem = form.items[nextIdx]

        let value = currentCell.value()
        if currentItem?.validate(value) ?? false {
            if let updatePath = currentItem?.path {
                form.data.set(value: value, forKeyPath: updatePath)
            }
            pageViewController.segue(
                to: Self.viewControllerForInput(input: nextItem),
                direction: .right)
        }
    }

    private static func viewControllerForInput(input: BFFormItem<Form.DataType>?)
        -> BFFormCell
    {
        switch input?.type {
        case .text, .password, .email, .otp:
            return BFFormTextView()
        default:
            fatalError("Unsupported form type \(input?.type)")
        }
    }

}
