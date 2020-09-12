//
//  QuickAccessUserCollectionCell.swift
//  Bonfire
//
//  Created by Daniel Gauthier on 2020-09-09.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Cartography
import UIKit

class QuickAccessUserCollectionCell: UITableViewCell {

    var users: [DummyPost.User] = [] {
        didSet {
            collectionView.reloadData()
        }
    }

    private let collectionView: UICollectionView = .make(cellReuseIdentifier: QuickAccessUserCell.reuseIdentifier, cellClass: QuickAccessUserCell.self, intrinsicallySized: false, allowsSelection: true, scrollDirection: .vertical)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(collectionView)
        constrain(collectionView) {
            $0.edges == $0.superview!.edges
        }

        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// TODO: Will need to massage the layout of the collection view a bit more to accommodate smaller phones (i.e. 1st gen SE).
// Currently, this works nicely for most phones, but you end up with only 2 awkwardly-spaced cells per row on an SE.
extension QuickAccessUserCollectionCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: 108, height: 120)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        UIEdgeInsets(top: 8, left: 14, bottom: 16, right: 14)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("did select")
    }
}

extension QuickAccessUserCollectionCell: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        users.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: QuickAccessUserCell.reuseIdentifier, for: indexPath) as! QuickAccessUserCell
        cell.user = users[indexPath.item]
        return cell
    }
}
