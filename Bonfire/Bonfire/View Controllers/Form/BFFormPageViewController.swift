//
//  BFFormCollectionViewController.swift
//  Bonfire
//
//  Created by James Dale on 13/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation
import UIKit

final class BFFormPageViewController: UIViewController {
    
    private let horizontalPageVC = UIPageViewController(transitionStyle: .scroll,
                                                        navigationOrientation: .horizontal,
                                                        options: [:])
    
    private var verticalPageVC = UIPageViewController(transitionStyle: .scroll,
                                                      navigationOrientation: .vertical,
                                                      options: [:])
    
    private let initialViewController: UIViewController
    
    enum Direction {
        case up
        case down
        case left
        case right
    }
    
    init(initialVC: UIViewController) {
        initialViewController = initialVC
        super.init(nibName: nil, bundle: nil)
        view.addSubview(horizontalPageVC.view)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        verticalPageVC.setViewControllers([initialViewController],
                                          direction: .forward,
                                          animated: false)
        horizontalPageVC.setViewControllers([verticalPageVC],
                                            direction: .forward,
                                            animated: false)
    }
    
    func segue(to viewController: UIViewController, direction: Direction) {
        switch direction {
        case .right:
            let newVerticalPageVC = UIPageViewController(transitionStyle: .scroll,
                                                         navigationOrientation: .vertical,
                                                         options: [:])
            
            newVerticalPageVC.setViewControllers([viewController],
                                                 direction: .forward,
                                                 animated: false)
            
            horizontalPageVC.setViewControllers([newVerticalPageVC],
                                                direction: .forward,
                                                animated: true) { (success) in
                self.verticalPageVC = newVerticalPageVC
                if success { viewController.updateViewConstraints() }
            }
        case .left:
            let newVerticalPageVC = UIPageViewController(transitionStyle: .scroll,
                                                         navigationOrientation: .vertical,
                                                         options: [:])
            
            newVerticalPageVC.setViewControllers([viewController],
                                                 direction: .reverse,
                                                 animated: false)
            
            horizontalPageVC.setViewControllers([newVerticalPageVC],
                                                direction: .reverse,
                                                animated: true) { (success) in
                self.verticalPageVC = newVerticalPageVC
                if success { viewController.updateViewConstraints() }
            }
        case .up:
            verticalPageVC.setViewControllers([viewController],
                                              direction: .forward,
                                              animated: true)
        case .down:
            verticalPageVC.setViewControllers([viewController],
                                              direction: .reverse,
                                              animated: true)
        }
    }
    
}
