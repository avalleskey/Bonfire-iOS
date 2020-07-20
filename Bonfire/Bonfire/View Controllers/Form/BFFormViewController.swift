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
        
        pageViewController.view.translatesAutoresizingMaskIntoConstraints  = false
        nextBtn.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            pageViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            pageViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            pageViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            nextBtn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                                            constant: -20),
            nextBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    @objc private func nextBtnTap(sender: UIButton) {
        guard let currentIdx = form.items.firstIndex(where: { $0 == currentItem }) else { return }
        let nextIdx = form.items.index(after: currentIdx)
        let nextItem = form.items[nextIdx]
        
        if currentItem?.validate() ?? false {
            if let updatePath = currentItem?.path {
//                form.data.set(value: "", forKeyPath: updatePath)
            }
            pageViewController.segue(to: Self.viewControllerForInput(input: nextItem),
                                     direction: .right)
        }
    }
    
    static func viewControllerForInput(input: BFFormItem<Form.DataType>?) -> UIViewController {
        switch input?.type {
        case .text, .password, .email, .otp:
            return BFFormTextView()
        default:
            fatalError("Unsupported form type \(input?.type)")
        }
    }
    
}
