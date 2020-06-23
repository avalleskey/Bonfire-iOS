//
//  ViewController.swift
//  Bonfire
//
//  Created by James Dale on 19/6/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit

final class HomeViewController: UIViewController {
    
    static var defaultTabBarItem: UITabBarItem {
        let item = UITabBarItem(title: Constants.TabBar.homeDefaultText,
                     image: Constants.TabBar.homeDefaultImage,
                     selectedImage: Constants.TabBar.createPostImage)
        item.tag = 1
        return item
    }
    
    let homeFeedTableView = BFFeedTableViewController()

    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) { view.backgroundColor = .systemBackground }
        
        view.addSubview(homeFeedTableView.view)
        
        updateViewConstraints()
    }
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        
        homeFeedTableView.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            homeFeedTableView.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            homeFeedTableView.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            homeFeedTableView.view.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            homeFeedTableView.view.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
        ])
    }

}
