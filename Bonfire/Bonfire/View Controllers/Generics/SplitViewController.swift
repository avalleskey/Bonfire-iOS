//
//  SplitViewController.swift
//  Bonfire
//
//  Created by Austin Valleskey on 9/22/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit
import Cartography

class SplitViewController<H: UIView, S: SheetFeedViewController>: BaseViewController, UIGestureRecognizerDelegate {
    var headerView: H
    var sheetViewController: S
    
    // Sheet Management
    enum SheetState {
        case expanded
        case collapsed
    }
    private let sheetContainerView = UIView()
    var sheetState: SheetState = .collapsed {
        didSet {
            if sheetState != oldValue {
                self.sheetViewController.tableView.isScrollEnabled = false
                
                let frameAnimator = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 0.7) {
                    switch self.sheetState {
                    case .expanded:
                        self.navigationBar.titleStackView.alpha = 1
                        self.navigationBar.titleStackView.transform = CGAffineTransform(scaleX: 1, y: 1)
                        self.sheetTopConstraint?.constant = 0
                        self.headerView.alpha = 0
                        self.headerView.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
                        self.view.layoutIfNeeded()
                    case .collapsed:
                        self.navigationBar.titleStackView.alpha = 0
                        self.navigationBar.titleStackView.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
                        self.headerView.alpha = 1
                        self.headerView.transform = CGAffineTransform(scaleX: 1, y: 1)
                        self.sheetTopConstraint?.constant = self.headerView.frame.size.height + 24
                        self.sheetViewController.tableView.contentOffset.y = 0
                        self.view.layoutIfNeeded()
                    }
                }

                frameAnimator.addCompletion { _ in
                    self.runningAnimations.removeAll()
                    
                    self.sheetViewController.tableView.isScrollEnabled = self.sheetState == .expanded
                }

                frameAnimator.startAnimation()
                runningAnimations.append(frameAnimator)
                
            }
        }
    }
    var runningAnimations = [UIViewPropertyAnimator]()
    var collapsedHeight: CGFloat {
        return self.headerView.frame.size.height + 24
    }
    var sheetTopConstraint: NSLayoutConstraint!
    
    init(headerView: H, sheetViewController: S, navigationBar: NavigationBar, scrollView: UIScrollView?, floatingButton: BFFloatingButton? = nil) {
        self.headerView = headerView
        self.sheetViewController = sheetViewController
        super.init(navigationBar: navigationBar, scrollView: scrollView, floatingButton: floatingButton)
        
        navigationBar.titleStackView.alpha = 0
        navigationBar.backgroundColor = .clear
        
        view.layoutIfNeeded()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpHeaderView()
        setUpSheet()
        loadData()
    }
    
    func setUpHeaderView() {
        view.addSubview(headerView)
        constrain(headerView, navigationBar) {
            $0.top == $1.bottom
            $0.leading == $0.superview!.leading
            $0.trailing == $0.superview!.trailing
        }
    }
    
    func setUpSheet() {
        sheetTopConstraint?.constant = self.headerView.frame.size.height + 24
        
        sheetContainerView.layer.cornerRadius = 28
        if #available(iOS 13.0, *) {
            sheetContainerView.layer.cornerCurve = .continuous
        }
        sheetContainerView.backgroundColor = Constants.Color.groupedBackground
        sheetContainerView.applyShadow(explicitPath: false, intensity: .sketch(color: .black, alpha: 0.08, x: 0, y: -1, blur: 3, spread: 0))
        view.add(subview: sheetContainerView)
        constrain(sheetContainerView, navigationBar) {
            $0.width == $0.superview!.width
            sheetTopConstraint = ($0.top == $1.bottom + collapsedHeight)
            $0.bottom == $0.superview!.bottom
        }
        
        let sheetMaskView = UIView()
        sheetMaskView.layer.masksToBounds = true
        sheetMaskView.layer.cornerRadius = sheetContainerView.layer.cornerRadius
        if #available(iOS 13.0, *) {
            sheetMaskView.layer.cornerCurve = .continuous
        }
        sheetContainerView.addSubview(sheetMaskView)
        constrain(sheetMaskView, sheetContainerView) {
            $0.edges == $1.edges
        }
        
        // Add Sheet View Controller as a child view
        addChild(sheetViewController)
        sheetMaskView.addSubview(sheetViewController.view)
        sheetViewController.didMove(toParent: self)
        constrain(sheetViewController.view, sheetMaskView) {
            $0.edges == $1.edges
        }
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleCardTap(_:)))
        sheetViewController.navigationBar.addGestureRecognizer(tapGestureRecognizer)
        
        let swipeUpGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(swipeUpGesture(_:)))
        swipeUpGestureRecognizer.direction = .up
        sheetContainerView.addGestureRecognizer(swipeUpGestureRecognizer)
        
        let swipeDownGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(swipeDownGesture(_:)))
        swipeDownGestureRecognizer.direction = .down
        swipeDownGestureRecognizer.delegate = self
        sheetContainerView.addGestureRecognizer(swipeDownGestureRecognizer)
        
        sheetViewController.tableView.panGestureRecognizer.require(toFail: swipeDownGestureRecognizer)
        
        if let gestureRecognizers = view.gestureRecognizers {
            for gestureRecognizer in gestureRecognizers {
                if gestureRecognizer is OneWayPanGestureRecognizer {
                    swipeUpGestureRecognizer.require(toFail: gestureRecognizer)
                    swipeDownGestureRecognizer.require(toFail: gestureRecognizer)
                }
            }
        }
    }
    
    func loadData() {
        
    }
    
    func updateWithColor(_ hex: String?, animated: Bool = false) {
        var color = Constants.Color.secondary
        if let hex = hex {
            color = UIColor(hex: hex)!
        }
        
        UIView.animate(withDuration: (animated ? 0.6 : 0), delay: 0.0, usingSpringWithDamping: 1, initialSpringVelocity: 0.0, options: .allowUserInteraction, animations: {
            self.view.tintColor = color
            self.view.backgroundColor = color
            self.navigationBar.color = color
            self.setNeedsStatusBarAppearanceUpdate()
        }, completion: { _ in
            self.navigationBar.backgroundColor = .clear
        })
    }
    
    @objc func swipeDownGesture(_ recognzier: UISwipeGestureRecognizer) {
        if sheetState == .expanded && sheetViewController.tableView.contentOffset.y <= 0 {
            sheetState = .collapsed
        }
    }
    @objc func swipeUpGesture(_ recognzier: UISwipeGestureRecognizer) {
        if sheetState == .collapsed {
            sheetState = .expanded
        }
    }
    
    private func toggleSheet() {
        switch sheetState {
            case .collapsed:
                sheetState = .expanded
            case .expanded:
                sheetState = .collapsed
        }
    }
    @objc func handleCardTap(_ recognzier: UITapGestureRecognizer) {
        switch recognzier.state {
        case .ended:
            toggleSheet()
        default:
            break
        }
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UISwipeGestureRecognizer {
            if let gestureRecognizer = gestureRecognizer as? UISwipeGestureRecognizer {
                return gestureRecognizer.direction == .down && sheetViewController.tableView.contentOffset.y <= 0
            }
        }
        
        return true
    }
}
