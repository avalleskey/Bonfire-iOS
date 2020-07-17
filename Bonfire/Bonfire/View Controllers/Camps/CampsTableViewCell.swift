//
//  CampsTableViewCell.swift
//  Bonfire
//
//  Created by James Dale on 22/6/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation
import UIKit

final class CampTableViewCell: UITableViewCell {
    
    static let reuseIdentifier = "CampTableViewCellReuseIdentifier"
    
    let campImageView: UIImageView = {
        let imageView = RoundedImageView()
        imageView.image = UIImage(named: "Austin")!
        return imageView
    }()
    
    let campNameLabel: UILabel = {
        let label = UILabel()
        label.text = "Illustration"
        label.font = UIFont.systemFont(ofSize: 17, weight: .bold).rounded()
        label.textColor = Constants.Color.primary
        return label
    }()
    
    let campSublineLabel: UILabel = {
        let label = UILabel()
        label.text = "#Illustration"
        label.font = UIFont.systemFont(ofSize: 15, weight: .semibold).rounded()
        label.textColor = Constants.Color.secondaryLabel
        return label
    }()
    
    let campTextStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        return stackView
    }()
    
    let campStreakLabel: UILabel = {
        let label = UILabel()
        label.text = "🔥🔥"
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureUI() {
        addSubview(campImageView)
        campTextStackView.addArrangedSubview(campNameLabel)
        campTextStackView.addArrangedSubview(campSublineLabel)
        addSubview(campTextStackView)
    }
    
    override func updateConstraints() {
        super.updateConstraints()
        
        
        campImageView.translatesAutoresizingMaskIntoConstraints = false
        campTextStackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            campImageView.leadingAnchor.constraint(equalTo: leadingAnchor,
                                                   constant: 12),
            campImageView.topAnchor.constraint(equalTo: topAnchor,
                                               constant: 12),
            campImageView.bottomAnchor.constraint(equalTo: bottomAnchor,
                                                  constant: -12),
            campImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            campImageView.widthAnchor.constraint(equalTo: campImageView.heightAnchor),
        ])
        
        NSLayoutConstraint.activate([
            campTextStackView.leadingAnchor.constraint(equalTo: campImageView.trailingAnchor,
                                                       constant: 12),
            campTextStackView.trailingAnchor.constraint(equalTo: trailingAnchor,
                                                        constant: -12),
            campTextStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }
    
}
