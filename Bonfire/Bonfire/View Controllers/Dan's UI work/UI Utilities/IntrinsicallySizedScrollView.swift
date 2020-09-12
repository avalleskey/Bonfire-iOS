//
//  IntrinsicallySizedScrollView.swift
//  Bonfire
//
//  Created by Daniel Gauthier on 2020-08-19.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit

public class IntrinsicallySizedScrollView: UIScrollView {

    public override var contentSize: CGSize {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }

    public override var intrinsicContentSize: CGSize {
        layoutIfNeeded()
        return CGSize(width: UIView.noIntrinsicMetric, height: contentSize.height + contentInset.top)
    }
}
