//
//  CampViewController.swift
//  Bonfire
//
//  Created by James Dale on 31/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit

final class CampViewController: UIViewController {

    private let feedTableView = BFFeedTableViewController()
    
    init() {
        super.init(nibName: nil, bundle: nil)
        
        view.backgroundColor = Constants.Color.brand
        navigationItem.title = "Camp Test"
        
        addChild(feedTableView)
        view.addSubview(feedTableView.view)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.delegate = self
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}

extension CampViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }
}

