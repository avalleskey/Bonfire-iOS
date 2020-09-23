//
//  UIFont.swift
//  Bonfire
//
//  Created by James Dale on 22/6/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit

extension UIFont {
    func rounded() -> UIFont {
        if #available(iOS 13.0, *), let roundedDescriptor = fontDescriptor.withDesign(.rounded) {
            return UIFont(descriptor: roundedDescriptor, size: pointSize)
        }
        return self
    }
}
