//
//  UIDevice+Extensions.swift
//  Bonfire
//
//  Created by Austin Valleskey on 9/17/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit

extension UIDevice {
    var cornerRadius: CGFloat {
        return UIDevice.current.hasNotch ? 38.5 : 0
    }
    
    var hasNotch: Bool {
        let bottom = UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0
        return bottom > 0
    }
}
