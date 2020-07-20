//
//  BFFormTextCell.swift
//  Bonfire
//
//  Created by James Dale on 18/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation
import UIKit

final class BFFormTextView: UIViewController, BFFormCell {
    
    let instructionLabel: UILabel = {
        let label = UILabel()
        label.text = "Enter text..."
        label.numberOfLines = 2
        return label
    }()
    
    let textField: BFTextField = {
        let textField = BFTextField()
        textField.placeholder = "Enter Value..."
        return textField
    }()
    
    init() {
        super.init(nibName: nil, bundle: nil)
        
        view.addSubview(instructionLabel)
        view.addSubview(textField)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        
        textField.translatesAutoresizingMaskIntoConstraints = false
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            textField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            textField.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            instructionLabel.bottomAnchor.constraint(equalTo: textField.topAnchor, constant: 80)
        ])
    }
}
