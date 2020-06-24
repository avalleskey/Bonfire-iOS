//
//  BFSegmentedControlButton.swift
//  Bonfire
//
//  Created by James Dale on 24/6/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation
import UIKit

final class BFSegmentedControlButton: UIButton {
    let item: BFSegmentedControlItem
    
    init(item: BFSegmentedControlItem) {
        self.item = item
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
