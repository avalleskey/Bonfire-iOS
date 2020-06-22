//
//  BFSegmentedControl.swift
//  Bonfire
//
//  Created by James Dale on 22/6/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation
import UIKit

final class BFSegmentedControl: UIView {
    
    let buttonStackView: UIStackView = {
        let stackView = UIStackView()
        return stackView
    }()
    
    init() {
        super.init(frame: .zero)
        addSubview(buttonStackView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addItem(_ item: BFSegmentedControlItem) {
        let itemBtn = UIButton()
        itemBtn.setTitle(item.title, for: .normal)
        itemBtn.setTitleColor(Constants.Color.label, for: .normal)
        itemBtn.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        itemBtn.titleLabel?.font = itemBtn.titleLabel?.font.rounded()
        itemBtn.contentEdgeInsets = .init(top: 8, left: 16, bottom: 8, right: 16)
        buttonStackView.addArrangedSubview(itemBtn)
    }
    
    func addItems(_ items: [BFSegmentedControlItem]) {
        items.forEach { addItem($0) }
    }
    
    override func updateConstraints() {
        super.updateConstraints()
        
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            buttonStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            buttonStackView.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
    }
    
}
