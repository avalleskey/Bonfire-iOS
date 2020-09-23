//
//  GenericHeaderView.swift
//  Bonfire
//
//  Created by Austin Valleskey on 31/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import BFCore
import UIKit
import Cartography

class GenericHeaderView<A: UIImageView>: UIView {
    let avatarDiameter: CGFloat = 124
    let avatarBorderWidth: CGFloat = 6
    
    let stackView = UIStackView(axis: .vertical, alignment: .center, spacing: 16)
    
    private let avatarContainerView = UIView()
    private let avatarImageView = A()
    var avatarUrl: URL? {
        didSet {
            avatarImageView.kf.setImage(with: avatarUrl)
        }
    }
    
    private let titleLabel = UILabel(size: 28, weight: .heavy, alignment: .center, multiline: true, dynamicTextSize: false)
    var title: String = "" {
        didSet {
            titleLabel.text = title
            titleLabel.isHidden = title.count == 0
        }
    }
    
    private let subtitleLabel = UILabel(size: 18, weight: .bold, alignment: .center)
    var subtitle: String? {
        didSet {
            subtitleLabel.text = subtitle
            subtitleLabel.isHidden = subtitle?.count == 0
            
            if oldValue?.count == 0 && !subtitleLabel.isHidden {
                self.subtitleLabel.alpha = 0
                self.subtitleLabel.isHidden = true
                
                UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.0, options: .allowUserInteraction, animations: {
                    self.subtitleLabel.alpha = 1
                    self.subtitleLabel.isHidden = false
//                    self.detailLabel.transform = CGAffineTransform(scaleX: 1, y: 1)
                }, completion: { _ in

                })
            }
        }
    }
    
    private let detailLabel = UILabel(size: 15, weight: .medium, alignment: .center)
    var detail: String? {
        didSet {
            detailLabel.text = detail
            detailLabel.isHidden = detail?.count == 0
            
            if oldValue?.count == 0 && !detailLabel.isHidden {
                self.detailLabel.alpha = 0
                self.detailLabel.isHidden = true
                
                UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.0, options: .allowUserInteraction, animations: {
                    self.detailLabel.alpha = 1
                    self.detailLabel.isHidden = false
//                    self.detailLabel.transform = CGAffineTransform(scaleX: 1, y: 1)
                }, completion: { _ in

                })
            }
        }
    }
    
    var color: UIColor = Constants.Color.secondary {
        didSet {
            let isLightForeground = color.isDarkColor
            let foregroundColor = isLightForeground ? UIColor.white : UIColor.black
            let shadowColor = (isLightForeground ? UIColor.black : UIColor.white).cgColor
            
            avatarContainerView.backgroundColor = foregroundColor
            titleLabel.textColor = foregroundColor
            subtitleLabel.textColor = foregroundColor
            detailLabel.textColor = foregroundColor
            
            avatarContainerView.layer.shadowColor = shadowColor
            titleLabel.layer.shadowColor = shadowColor
            subtitleLabel.layer.shadowColor = shadowColor
            detailLabel.layer.shadowColor = shadowColor
        }
    }
    
    private let actionsStackView = UIStackView(axis: .horizontal, alignment: .center, distribution: .fillEqually , spacing: 12)
    
    let primaryAction: BFActionButton = {
        let action = BFActionButton(style: .primary(color: .red))
        action.setTitle("Primary", for: .normal)
        action.setImage(UIImage(named: "MessageIcon"), for: .normal)
        return action
    }()
    let secondaryAction: BFActionButton = {
        let action = BFActionButton(style: .secondary(color: .red))
        action.setTitle("Message", for: .normal)
        action.setImage(UIImage(named: "MessageIcon"), for: .normal)
        return action
    }()
    
    init() {
        super.init(frame: .zero)
        setUpStackView()
        setUpAvatarViews()
        setUpTitleLabel()
        setUpSubtitleLabel()
        setUpDescriptionLabel()
        setUpActionStackView()
        setUpActions()
        layoutIfNeeded()
    }
    
    private func setUpStackView() {
        addSubview(stackView)
        constrain(stackView) {
            $0.leading == $0.superview!.leading
            $0.trailing == $0.superview!.trailing
        }
        
        constrain(self, stackView) {
            $0.edges == $1.edges
        }
    }
    
    private func setUpAvatarViews() {
        avatarContainerView.layer.cornerRadius = (avatarDiameter + (avatarBorderWidth * 2)) / 2
        avatarContainerView.backgroundColor = .white
        avatarContainerView.layer.shadowOffset = CGSize(width: 0, height: 1)
        avatarContainerView.layer.shadowRadius = 2
        avatarContainerView.layer.shadowColor = UIColor.black.cgColor
        avatarContainerView.layer.shadowOpacity = 0.06
        stackView.addArrangedSubview(avatarContainerView)
        constrain(avatarContainerView) {
            $0.width == (avatarDiameter + (avatarBorderWidth * 2))
            $0.height == (avatarDiameter + (avatarBorderWidth * 2))
        }
        stackView.setCustomSpacing(12, after: avatarContainerView)
        
        avatarImageView.layer.cornerRadius = avatarDiameter / 2
        avatarImageView.layer.masksToBounds = true
        avatarContainerView.addSubview(avatarImageView)
        constrain(avatarImageView) {
            $0.width == avatarDiameter
            $0.height == avatarDiameter
            $0.center == $0.superview!.center
        }
    }
    
    private func setUpTitleLabel() {
        titleLabel.text = "Display Name"
        titleLabel.layer.shadowOffset = CGSize(width: 0, height: 1)
        titleLabel.layer.shadowOpacity = 0.06
        titleLabel.layer.shadowRadius = 2
        titleLabel.layer.shadowColor = UIColor.black.cgColor
        stackView.addArrangedSubview(titleLabel)
        constrain(titleLabel) {
            $0.leading == $0.superview!.leading
            $0.trailing == $0.superview!.trailing
        }
        stackView.setCustomSpacing(4, after: titleLabel)
    }
    
    private func setUpSubtitleLabel() {
        subtitleLabel.alpha = 0.75
        subtitleLabel.text = "@username"
        subtitleLabel.layer.shadowOffset = CGSize(width: 0, height: 1)
        subtitleLabel.layer.shadowOpacity = 0.06
        subtitleLabel.layer.shadowRadius = 2
        subtitleLabel.layer.shadowColor = UIColor.black.cgColor
        stackView.addArrangedSubview(subtitleLabel)
        constrain(subtitleLabel) {
            $0.leading == $0.superview!.leading
            $0.trailing == $0.superview!.trailing
        }
        stackView.setCustomSpacing(12, after: subtitleLabel)
    }
    
    private func setUpDescriptionLabel() {
        detailLabel.isHidden = true
        detailLabel.text = ""
        detailLabel.layer.shadowOffset = CGSize(width: 0, height: 1)
        detailLabel.layer.shadowOpacity = 0.06
        detailLabel.layer.shadowRadius = 2
        detailLabel.layer.shadowColor = UIColor.black.cgColor
        stackView.addArrangedSubview(detailLabel)
        constrain(detailLabel) {
            $0.width == $0.superview!.width - 48
        }
    }
    
    private func setUpActionStackView() {
        stackView.addArrangedSubview(actionsStackView)
        constrain(actionsStackView) {
            $0.height == 44
            $0.leading == $0.superview!.leading + 16
            $0.trailing == $0.superview!.trailing - 16
        }
    }
    
    private func setUpActions() {
        actionsStackView.addArrangedSubview(primaryAction)
        actionsStackView.addArrangedSubview(secondaryAction)
        
        constrain(primaryAction, secondaryAction) {
            $0.height == $0.superview!.height
            $1.height == $1.superview!.height
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
