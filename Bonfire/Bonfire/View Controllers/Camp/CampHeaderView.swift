//
//  CampHeaderView.swift
//  Bonfire
//
//  Created by James Dale on 31/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit

final class CampHeaderView: UIView {

    let pageViewController = UIPageViewController()

    let joinBtn: UIButton = {
        let btn = UIButton()
        btn.setTitle("Join", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold).rounded()
        return btn
    }()

    let aboutBtn: UIButton = {
        let btn = UIButton()
        btn.setTitle("About", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold).rounded()
        return btn
    }()

    let actionsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.spacing = 12
        return stackView
    }()

    init() {
        super.init(frame: .zero)

        pageViewController.dataSource = self
        pageViewController.setViewControllers(
            [ProfileSummaryPageViewController()],
            direction: .forward,
            animated: false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension CampHeaderView: UIPageViewControllerDataSource {
    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        nil
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        nil
    }
}
