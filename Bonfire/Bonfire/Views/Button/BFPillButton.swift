//
//  BFPillButton.swift
//  Bonfire
//
//  Created by James Dale on 24/6/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation
import UIKit

final class BFPillButton: BFBouncyButton {
    init(title: String, icon: String?, target: AnyObject?, action: Selector?) {
        super.init(frame: .zero)
                
        setTitle(title, for: .normal)
        
        var titleImageSpacing: CGFloat = 0
        if (icon != nil) {
            setImage(UIImage(named: icon!)?.withRenderingMode(.alwaysTemplate), for: .normal)
            
            titleImageSpacing = 8
            titleEdgeInsets = .init(top: 0, left: titleImageSpacing, bottom: 0, right: 0)
            imageEdgeInsets = .init(top: 0, left: 0, bottom: 0, right: titleImageSpacing)
        }
        if (target != nil) {
            addTarget(target, action: action!, for: .touchUpInside)
        }
        
        backgroundColor = Constants.Color.pillBackground
        setTitleColor(Constants.Color.primary, for: .normal)
        tintColor = Constants.Color.primary
        contentEdgeInsets = .init(top: 0, left: 16, bottom: 0, right: 16)
        titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold).rounded()
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.12
        layer.shadowOffset = .init(width: 0, height: 2)
        layer.cornerRadius = 20
        layer.shadowRadius = 3
        
        frame = CGRect(x: 0, y: 0, width: intrinsicContentSize.width + titleImageSpacing, height: 40)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
