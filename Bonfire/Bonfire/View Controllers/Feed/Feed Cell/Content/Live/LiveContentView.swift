//
//  LiveContentView.swift
//  Bonfire
//
//  Created by Daniel Gauthier on 2020-08-21.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit
import Cartography

class LiveContentView: UIView {

    private var camps: [DummyPost.Camp]

    private let collectionView: UICollectionView = .make(cellReuseIdentifier: LiveContentCell.reuseIdentifier, cellClass: LiveContentCell.self, allowsSelection: true, scrollDirection: .horizontal)

    init(camps: [DummyPost.Camp]) {
        self.camps = camps
        super.init(frame: .zero)

        setUpCollectionView()
        collectionView.reloadData()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .clear
        addSubview(collectionView)
        constrain(collectionView) {
            $0.height == 106
            $0.edges == $0.superview!.edges ~ .init(999)
        }
    }
}

extension LiveContentView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: 82, height: 82)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        UIEdgeInsets(top: 8, left: 16, bottom: 16, right: 16)
    }
}

extension LiveContentView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        camps.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: LiveContentCell.reuseIdentifier, for: indexPath) as! LiveContentCell
        cell.camp = camps[indexPath.item]
        return cell
    }
}
