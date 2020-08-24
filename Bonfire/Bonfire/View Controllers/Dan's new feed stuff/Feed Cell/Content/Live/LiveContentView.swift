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
    private var dataSource: UICollectionViewDiffableDataSource<Int, DummyPost.Camp>!

    init(camps: [DummyPost.Camp]) {
        self.camps = camps
        super.init(frame: .zero)

        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView, cellProvider: { [weak self] collectionView, indexPath, camp -> UICollectionViewCell? in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: LiveContentCell.reuseIdentifier, for: indexPath) as? LiveContentCell else { return nil }
            cell.camp = self?.camps[indexPath.row]
            return cell
        })

        setUpCollectionView()
        updateDataSource()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpCollectionView() {
        collectionView.delegate = self
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .clear
        addSubview(collectionView)
        constrain(collectionView) {
            $0.height == 104
            $0.edges == $0.superview!.edges
        }
    }

    private func updateDataSource() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, DummyPost.Camp>()
        snapshot.appendSections([0])
        snapshot.appendItems(camps)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}

extension LiveContentView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: 80, height: 80)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        UIEdgeInsets(top: 8, left: 16, bottom: 16, right: 16)
    }
}
