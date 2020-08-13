//
//  CampSummaryPageViewController.swift
//  Bonfire
//
//  Created by James Dale on 31/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit

final class CampSummaryPageViewController: UIViewController {

    let imageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()

    let primaryLabel: UILabel = {
        let label = UILabel()
        label.text = "304 campers"
        return label
    }()

    let secondaryLabel: UILabel = {
        let label = UILabel()
        label.text = "Private"
        return label
    }()

    init() {
        super.init(nibName: nil, bundle: nil)

        view.addSubview(imageView)
        view.addSubview(primaryLabel)
        view.addSubview(secondaryLabel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
