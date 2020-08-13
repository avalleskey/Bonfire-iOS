//
//  PinCollectionViewCell.swift
//  Bonfire
//
//  Created by James Dale on 12/8/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit

final class PinCollectionViewCell: UICollectionViewCell {

    static let reuseIdentifier = "PinCollectionViewCell"

    var pinView: UIView? {
        didSet {
            if oldValue != nil { oldValue?.removeFromSuperview() }
            if let newValue = pinView { contentView.addSubview(newValue) }
            updateConstraints()
        }
    }

    let pinTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15, weight: .bold).rounded()
        label.tintColor = Constants.Color.secondary
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: .zero)

        contentView.addSubview(pinTitleLabel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        pinView?.removeFromSuperview()
        pinView = nil
    }

    override func updateConstraints() {
        super.updateConstraints()

        pinTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        pinView?.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            pinTitleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            pinTitleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
        ])

        NSLayoutConstraint.activate(
            [
                pinView?.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
                pinView?.bottomAnchor.constraint(equalTo: pinTitleLabel.topAnchor, constant: -5),
                pinView?.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 5),
                pinView?.trailingAnchor.constraint(
                    equalTo: contentView.trailingAnchor, constant: -5),
            ].compactMap { $0 })
    }

}
