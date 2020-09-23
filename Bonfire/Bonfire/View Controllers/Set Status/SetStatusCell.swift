//
//  SetStatusCell.swift
//  Bonfire
//
//  Created by Austin Valleskey on 9/16/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import BFCore
import Cartography
import UIKit

class SetStatusCell: UITableViewCell {

    var emoji: String! {
        didSet {
            emojiLabel.text = emoji
        }
    }
    
    var status: String! {
        didSet {
            statusLabel.text = status
        }
    }

    private let emojiLabel = UILabel(size: 28, weight: .regular, text: "💬")
    private let statusLabel = UILabel(size: 18, weight: .bold, color: Constants.Color.primary)

    let separatorView = UIView(backgroundColor: Constants.Color.separatorColor, height: 1 / UIScreen.main.scale)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
        backgroundColor = .clear
        
        setUpText()
        setUpSeparatorView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    private func setUpText() {
        contentView.addSubview(emojiLabel)
        contentView.addSubview(statusLabel)

        constrain(emojiLabel) {
            $0.leading == $0.superview!.leading + 12
            $0.centerY == $0.superview!.centerY
            $0.width == 32
        }
        
        constrain(statusLabel, emojiLabel) {
            $0.leading == $1.trailing + 12
            $0.centerY == $0.superview!.centerY
            $0.trailing == $0.superview!.trailing - 12
        }
    }

    private func setUpSeparatorView() {
        contentView.addSubview(separatorView)
        constrain(separatorView, statusLabel) {
            $0.leading == $1.leading
            $0.trailing == $0.superview!.trailing
            $0.bottom == $0.superview!.bottom
        }
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
