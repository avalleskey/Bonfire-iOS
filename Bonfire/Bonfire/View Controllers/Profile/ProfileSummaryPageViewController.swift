//
//  ProfileSummaryPageView.swift
//  Bonfire
//
//  Created by James Dale on 31/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit

final class ProfileSummaryPageViewController: UIViewController {
    
    let imageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
    
    let primaryLabel: UILabel = {
        let label = UILabel()
        label.text = "303k camps  45 friends"
        label.font = UIFont.systemFont(ofSize: 16, weight: .bold).rounded()
        label.textAlignment = .center
        return label
    }()
    
    let secondaryLabel: UILabel = {
        let label = UILabel()
        label.text = "340,203 notes"
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular).rounded()
        label.textAlignment = .center
        return label
    }()
    
    let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        return stackView
    }()
    
    init() {
        super.init(nibName: nil, bundle: nil)
        
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(primaryLabel)
        stackView.addArrangedSubview(secondaryLabel)
        
        view.addSubview(stackView)
        
        updateViewConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }
}
