//
//  PinCollectionViewController.swift
//  Bonfire
//
//  Created by James Dale on 12/8/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import BFCore
import Kingfisher
import UIKit

final class PinCollectionViewController: UICollectionViewController {

    private let flow = UICollectionViewFlowLayout()

    var pins: [Pin] = [] {
        didSet {
            collectionView.reloadData()
        }
    }

    init() {
        flow.sectionInset = .init(
            top: 24,
            left: 20,
            bottom: 20,
            right: 20)
        super.init(collectionViewLayout: flow)
        collectionView.register(
            PinCollectionViewCell.self,
            forCellWithReuseIdentifier: PinCollectionViewCell.reuseIdentifier)
        collectionView.backgroundColor = .clear
        flow.itemSize = CGSize(width: 96, height: 120)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func collectionView(
        _ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell =
            collectionView.dequeueReusableCell(
                withReuseIdentifier: PinCollectionViewCell.reuseIdentifier,
                for: indexPath) as! PinCollectionViewCell
        let pin = pins[indexPath.item]

        switch pin.object {
        case is User:
            guard let user = pin.object as? User,
                let imageURL = user.attributes.media?.avatar?.full?.url
            else { return cell }
            let imageView = RoundedImageView(image: nil)
            imageView.kf.setImage(with: imageURL, options: [.cacheOriginalImage])
            cell.pinTitleLabel.text = user.attributes.shortDisplayName
            cell.pinView = imageView
        case is Camp:
            guard let camp = pin.object as? Camp,
                let imageURL = camp.attributes.media?.avatar?.full?.url
            else { return cell }
            let imageView = RoundedImageView(image: nil)
            imageView.kf.setImage(with: imageURL, options: [.cacheOriginalImage])
            cell.pinTitleLabel.text = camp.attributes.title
            cell.pinView = imageView
        default:
            fatalError("Unknown pin object type")
        }
        return cell
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }

    override func collectionView(
        _ collectionView: UICollectionView, numberOfItemsInSection section: Int
    ) -> Int {
        pins.count
    }

}

extension PinCollectionViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let width: CGFloat =
            collectionView.bounds.width / 3.0 - flow.sectionInset.left - flow.sectionInset.right
        let height: CGFloat = 120.0

        return CGSize(width: width, height: height)
    }

    func collectionView(
        _ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int
    ) -> CGFloat {
        20
    }
}
