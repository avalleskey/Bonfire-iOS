//
//  QuickAccessUserCollectionCell.swift
//  Bonfire
//
//  Created by Daniel Gauthier on 2020-09-09.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Cartography
import UIKit

protocol QuickAccessUserCollectionCellDelegate: AnyObject {
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath)
}
    
class QuickAccessUserCollectionCell: UITableViewCell {

    weak var delegate: QuickAccessUserCollectionCellDelegate?
    
    var users: [DummyPost.User] = [] {
        didSet {
            collectionView.reloadData()
            collectionView.layoutIfNeeded()
        }
    }

    private let collectionView: UICollectionView = .make(cellReuseIdentifier: QuickAccessUserCell.reuseIdentifier, cellClass: QuickAccessUserCell.self, intrinsicallySized: true, allowsSelection: true, scrollDirection: .vertical)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(collectionView)
        constrain(collectionView) {
            $0.edges == $0.superview!.edges
        }

        backgroundColor = .clear
        contentView.backgroundColor = .clear
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isScrollEnabled = false
        
        if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// TODO: Will need to massage the layout of the collection view a bit more to accommodate smaller phones (i.e. 1st gen SE).
// Currently, this works nicely for most phones, but you end up with only 2 awkwardly-spaced cells per row on an SE.
extension QuickAccessUserCollectionCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: floor((collectionView.frame.size.width - 16 * 2 - 12 * 2) / 3), height: 118)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        UIEdgeInsets(top: 8, left: 16, bottom: 16, right: 16)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 16
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 12
    }
    
}

extension QuickAccessUserCollectionCell: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return users.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: QuickAccessUserCell.reuseIdentifier, for: indexPath) as! QuickAccessUserCell
        cell.user = users[indexPath.item]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.collectionView(collectionView, didDeselectItemAt: indexPath)
    }
    
}
