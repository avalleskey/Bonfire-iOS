//
//  BFFormViewController.swift
//  Bonfire
//
//  Created by James Dale on 18/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation
import UIKit

final class BFFormViewController: UIViewController {
    
    private let collectionViewController: BFPageViewController
    
    init(form: BFForm) {
        collectionViewController = BFPageViewController(initialVC: Self.viewControllerForInput(input: form.items.first!))
        super.init(nibName: nil, bundle: nil)
        view.backgroundColor = .white
        view.addSubview(collectionViewController.view)
        
        updateViewConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        
        collectionViewController.view.translatesAutoresizingMaskIntoConstraints  = false
        
        NSLayoutConstraint.activate([
            collectionViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            collectionViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    static func viewControllerForInput(input: BFFormItem) -> UIViewController {
        switch input.type {
        case .text:
            return BFFormTextView()
        default:
            fatalError("Unsupported form type")
        }
    }
    
}
