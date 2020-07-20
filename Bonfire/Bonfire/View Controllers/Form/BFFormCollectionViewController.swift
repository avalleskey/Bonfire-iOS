//
//  BFFormCollectionViewController.swift
//  Bonfire
//
//  Created by James Dale on 13/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation
import UIKit

final class BFPageViewController: UIViewController {
    
    let pageVC = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .vertical, options: [:])
    
    let initialViewController: UIViewController
        
    init(initialVC: UIViewController) {
        initialViewController = initialVC
        super.init(nibName: nil, bundle: nil)
        view.backgroundColor = .red
        view.addSubview(pageVC.view)
        pageVC.dataSource = self
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        let nestedPageVC = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: [:])
        nestedPageVC.dataSource = self
        nestedPageVC.setViewControllers([initialViewController],
                                        direction: .forward,
                                        animated: true)
        pageVC.setViewControllers([nestedPageVC],
                                  direction: .forward,
                                  animated: true)
    }
    
}

extension BFPageViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if pageViewController == pageVC {
            let nestedPageVC = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: [:])
            nestedPageVC.dataSource = self
            nestedPageVC.setViewControllers([initialViewController],
                                            direction: .forward,
                                            animated: true)
            return nestedPageVC
        }
        return initialViewController
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if pageViewController == pageVC {
            let nestedPageVC = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: [:])
            nestedPageVC.dataSource = self
            nestedPageVC.setViewControllers([initialViewController],
                                            direction: .forward,
                                            animated: true)
            return nestedPageVC
        }
        return initialViewController
    }
}
