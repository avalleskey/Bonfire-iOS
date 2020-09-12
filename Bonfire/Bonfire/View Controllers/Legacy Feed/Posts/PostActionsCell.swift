//
//  PostActionView.swift
//  Bonfire
//
//  Created by James Dale on 22/6/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation
import UIKit

final class PostActionsCell: UITableViewCell, BFPostCell {

    //static let reuseIdentifier = "PostActionsCellIdentifier"
    
    static let baseHeight: CGFloat = 36
    static let edgeInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 16, right: 0)
    static let rowHeight: CGFloat = edgeInsets.top + 36 + edgeInsets.bottom

    let repliesBtn: UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage(named: "ReplyThreshold0"), for: .normal)
        btn.setTitle("11 notes", for: .normal)
        btn.setTitleColor(.gray, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold).rounded()
        btn.titleEdgeInsets = .init(top: 0, left: 13, bottom: 0, right: -13)
        btn.contentMode = .center
        return btn
    }()

    let reactionsBtn: UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage(named: "Reactions"), for: .normal)
        return btn
    }()

    let shareBtn: UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage(named: "Share"), for: .normal)
        return btn
    }()
    
    let moreBtn: UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage(named: "PostMoreIcon"), for: .normal)
        btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        return btn
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(repliesBtn)
        contentView.addSubview(reactionsBtn)
        contentView.addSubview(shareBtn)
        contentView.addSubview(moreBtn)

        updateConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateConstraints() {
        super.updateConstraints()

        repliesBtn.translatesAutoresizingMaskIntoConstraints = false
        reactionsBtn.translatesAutoresizingMaskIntoConstraints = false
        shareBtn.translatesAutoresizingMaskIntoConstraints = false
        moreBtn.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            repliesBtn.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor,
                constant: 17),
            repliesBtn.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            shareBtn.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            shareBtn.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            reactionsBtn.trailingAnchor.constraint(equalTo: shareBtn.leadingAnchor, constant: -20),
            reactionsBtn.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            moreBtn.topAnchor.constraint(equalTo: contentView.topAnchor, constant: PostActionsCell.edgeInsets.top),
            moreBtn.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            moreBtn.heightAnchor.constraint(equalToConstant: PostActionsCell.baseHeight),
        ])
    }
}
