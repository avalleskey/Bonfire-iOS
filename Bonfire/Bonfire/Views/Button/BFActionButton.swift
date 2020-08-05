//
//  BFActionButton.swift
//  Bonfire
//
//  Created by James Dale on 6/8/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit

final class BFActionButton: UIButton {
    
    enum Style {
        case primary
        case secondary
    }
    
    init(style: Style) {
        super.init(frame: .zero)
        
        switch style {
        case .primary:
            backgroundColor = .white
        case .secondary:
            backgroundColor = UIColor(displayP3Red: 1, green: 1, blue: 1, alpha: 0.2)
        }
        tintColor = Constants.Color.primary
        
        titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold).rounded()
        layer.cornerRadius = 14
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.08
        layer.shadowOffset = .init(width: 0, height: 1)
        layer.cornerRadius = 20
        layer.shadowRadius = 3
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
