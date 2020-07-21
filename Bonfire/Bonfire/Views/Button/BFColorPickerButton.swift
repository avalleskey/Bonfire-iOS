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
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
