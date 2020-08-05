//
//  ProfileHeaderView.swift
//  Bonfire
//
//  Created by James Dale on 31/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit

final class ProfileHeaderView: UIView {
    
    let pageViewController = UIPageViewController()
    
    let addFriendBtn: UIButton = {
        let btn = UIButton()
        btn.setTitle("Add Friend", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold).rounded()
        return btn
    }()
    
    let messageBtn: UIButton = {
        let btn = UIButton()
        btn.setTitle("Message", for: .normal)
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
        
        backgroundColor = .red
        pageViewController.dataSource = self
        pageViewController.setViewControllers([ProfileSummaryPageViewController()],
                                              direction: .forward,
                                              animated: false)
        
        actionsStackView.addArrangedSubview(addFriendBtn)
        actionsStackView.addArrangedSubview(messageBtn)
        
        addSubview(pageViewController.view)
        addSubview(actionsStackView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateConstraints() {
        super.updateConstraints()
        
        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            pageViewController.view.topAnchor.constraint(equalTo: topAnchor),
            pageViewController.view.bottomAnchor.constraint(equalTo: centerYAnchor),
            pageViewController.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            pageViewController.view.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }
    
}

extension ProfileHeaderView: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        nil
    }
}
