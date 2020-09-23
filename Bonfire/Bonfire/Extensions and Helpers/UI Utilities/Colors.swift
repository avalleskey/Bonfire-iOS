//
//  Colors.swift
//  Bonfire
//
//  Created by Daniel Gauthier on 2020-08-24.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit

// TODO: Merge this with colors in Constants.swift, and alter some of these colors in dark mode.

extension UIColor {
    static var liveAudioTop: UIColor { UIColor(displayP3Red: 46 / 255, green: 0 / 255, blue: 255 / 255, alpha: 1.00) }
    static var liveAudioBottom: UIColor { UIColor(displayP3Red: 248 / 255, green: 0 / 255, blue: 255 / 255, alpha: 1.00) }
    static var liveVideoTop: UIColor { UIColor(displayP3Red: 255 / 255, green: 0 / 255, blue: 0 / 255, alpha: 1.00) }
    static var liveVideoBottom: UIColor { UIColor(displayP3Red: 255 / 255, green: 127 / 255, blue: 0 / 255, alpha: 1.00) }
    static var liveChatTop: UIColor { UIColor(displayP3Red: 100 / 255, green: 217 / 255, blue: 35 / 255, alpha: 1.00) }
    static var liveChatBottom: UIColor { UIColor(displayP3Red: 0 / 255, green: 211 / 255, blue: 255 / 255, alpha: 1.00) }
    static var liveTop: UIColor { UIColor(displayP3Red: 1.00, green: 0.00, blue: 0.71, alpha: 1.00) }
    static var liveBottom: UIColor { UIColor(displayP3Red: 0.90, green: 0.49, blue: 0.00, alpha: 1.00) }
    static var suggestedTop: UIColor { UIColor(displayP3Red: 0.85, green: 0.21, blue: 1.00, alpha: 1.00) }
    static var suggestedBottom: UIColor { UIColor(displayP3Red: 0.48, green: 0.21, blue: 1.00, alpha: 1.00) }
    static var contentGray: UIColor { UIColor(displayP3Red: 240 / 255, green: 240 / 255, blue: 242 / 255, alpha: 1.0) }
    static var separatorGray: UIColor { UIColor(displayP3Red: 238 / 255, green: 238 / 255, blue: 240 / 255, alpha: 1.0) }
    static var onlineGreen: UIColor { UIColor(displayP3Red: 50 / 255, green: 215 / 255, blue: 75 / 255, alpha: 1.0) }
    static var background: UIColor { .white }
    static var text: UIColor { UIColor(displayP3Red: 28 / 255, green: 28 / 255, blue: 30 / 255, alpha: 1.0) }
    static var secondaryText: UIColor { UIColor(displayP3Red: 142 / 255, green: 142 / 255, blue: 147 / 255, alpha: 1.0) }
    static var tertiaryText: UIColor { UIColor(displayP3Red: 28 / 255, green: 28 / 255, blue: 30 / 255, alpha: 0.25) }
    static var fade: UIColor { UIColor.black.withAlphaComponent(0.2) }
    static var darkFade: UIColor { UIColor.black.withAlphaComponent(0.4) }
}
