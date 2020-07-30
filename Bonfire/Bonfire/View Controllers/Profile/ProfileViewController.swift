//
//  ProfileViewController.swift
//  Bonfire
//
//  Created by James Dale on 29/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit

final class ProfileViewController: UIViewController {

    private let feedTableView = BFFeedTableViewController()
    
    init() {
        super.init(nibName: nil, bundle: nil)
        
        view.backgroundColor = Constants.Color.brand
        navigationItem.title = "John Smith"
        
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

// We need this to fix a nasty issue with tab bar controller and navigation controller together
extension ProfileViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }
}
