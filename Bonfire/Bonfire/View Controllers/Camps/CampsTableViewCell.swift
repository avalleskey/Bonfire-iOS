//
//  CampsTableViewCell.swift
//  Bonfire
//
//  Created by James Dale on 22/6/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation
import UIKit
import BFCore

final class CampTableViewCell: UITableViewCell {

    static let reuseIdentifier = "CampTableViewCellReuseIdentifier"

    func updateWithCamp(camp: Camp) {
        campNameLabel.text = String(htmlEncodedString: camp.attributes.title)
        campSublineLabel.text = String(htmlEncodedString: camp.attributes.description)

        if let url = camp.attributes.media?.avatar?.full?.url {
            campImageView.backgroundColor = .systemGray
            campImageView.tintColor = Constants.Color.systemBackground
            campImageView.kf.setImage(
                with: url,
                placeholder: UIImage(named: "DefaultCampAvatar_light")?.withRenderingMode(.alwaysTemplate),
                options: [
                    .scaleFactor(UIScreen.main.scale),
                    .transition(.fade(1)),
                    .cacheOriginalImage
                ])
            {
                result in
                switch result {
                    case .success(_):
                        self.campImageView.backgroundColor = .clear
                    case .failure(_):
                        break
                }
            }

        } else {
            let campColor = UIColor(hex: camp.attributes.color)
            campImageView.backgroundColor = campColor
            if campColor?.isDarkColor == true {
                campImageView.image = UIImage(named: "DefaultCampAvatar_light")
            } else {
                campImageView.image = UIImage(named: "DefaultCampAvatar_dark")
            }
        }
    }
    
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
        label.textColor = Constants.Color.secondary
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
        selectionStyle = .none
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
            campImageView.leadingAnchor.constraint(
                equalTo: leadingAnchor,
                constant: 12),
            campImageView.topAnchor.constraint(
                equalTo: topAnchor,
                constant: 12),
            campImageView.bottomAnchor.constraint(
                equalTo: bottomAnchor,
                constant: -12),
            campImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            campImageView.widthAnchor.constraint(equalTo: campImageView.heightAnchor),
        ])

        NSLayoutConstraint.activate([
            campTextStackView.leadingAnchor.constraint(
                equalTo: campImageView.trailingAnchor,
                constant: 12),
            campTextStackView.trailingAnchor.constraint(
                equalTo: trailingAnchor,
                constant: -12),
            campTextStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)

        UIView.animate(
            withDuration: 0.185, delay: 0, options: [.curveEaseOut],
            animations: {
                if highlighted {
                    self.backgroundColor = Constants.Color.cellHighlightedBackground
                } else {
                    self.backgroundColor = nil
                }
            }, completion: nil)
    }
}
