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
    
    let selectionView: UIView = {
        let view = UIView()
        view.backgroundColor = .gray
        view.layer.cornerRadius = 18
        return view
    }()
    
    let buttonStackView: UIStackView = {
        let stackView = UIStackView()
        return stackView
    }()
    
    private var selectionConstraints = [NSLayoutConstraint]()
    
    private var items = [BFSegmentedControlItem]()
    
    init() {
        super.init(frame: .zero)
        addSubview(selectionView)
        addSubview(buttonStackView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addItem(_ item: BFSegmentedControlItem) {
        let itemBtn = BFSegmentedControlButton(item: item)
        items.append(item)
        itemBtn.setTitle(item.title, for: .normal)
        itemBtn.setTitleColor(Constants.Color.label, for: .normal)
        itemBtn.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        itemBtn.titleLabel?.font = itemBtn.titleLabel?.font.rounded()
        itemBtn.contentEdgeInsets = .init(top: 8, left: 16, bottom: 8, right: 16)
        itemBtn.addTarget(self, action: #selector(selected(button:)), for: .touchUpInside)
        buttonStackView.addArrangedSubview(itemBtn)
    }
    
    func addItems(_ items: [BFSegmentedControlItem]) {
        items.forEach { addItem($0) }
    }
    
    @objc private func selected(button: BFSegmentedControlButton) {
        UIView.animate(withDuration: 0.3) {
            NSLayoutConstraint.deactivate(self.selectionConstraints)
            self.selectionConstraints = [
                self.selectionView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
                self.selectionView.centerXAnchor.constraint(equalTo: button.centerXAnchor),
                self.selectionView.widthAnchor.constraint(equalTo: button.widthAnchor),
                self.selectionView.heightAnchor.constraint(equalTo: button.heightAnchor)
            ]
            NSLayoutConstraint.activate(self.selectionConstraints)
            self.selectionView.layoutIfNeeded()
        }
    }
    
    override func updateConstraints() {
        super.updateConstraints()
        
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        selectionView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            buttonStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            buttonStackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            
            selectionView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
}
