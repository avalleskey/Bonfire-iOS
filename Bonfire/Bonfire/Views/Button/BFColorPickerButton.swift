//
//  BFColorPickerButton.swift
//  Bonfire
//
//  Created by James Dale on 22/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation
import UIKit

final class BFColorPickerButton: UIButton {
    // TODO: Implement
    
    let color: UIColor
    
    init(color: UIColor) {
        self.color = color
        super.init(frame: .zero)
        backgroundColor = color
        
        widthAnchor.constraint(equalTo: heightAnchor).isActive = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
