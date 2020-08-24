//
//  IntrinsicallySizedCollectionView.swift
//  Bonfire
//
//  Created by Daniel Gauthier on 2020-08-19.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit

public class IntrinsicallySizedCollectionView: UICollectionView {

    public override func layoutSubviews() {
        super.layoutSubviews()
        if bounds.size != intrinsicContentSize {
            invalidateIntrinsicContentSize()
        }
    }

    public override var intrinsicContentSize: CGSize {
        return collectionViewLayout.collectionViewContentSize
    }
}
