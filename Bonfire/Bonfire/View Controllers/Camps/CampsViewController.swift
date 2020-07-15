//
//  CampsViewController.swift
//  Bonfire
//
//  Created by James Dale on 20/6/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation
import UIKit

final class CampsViewController: UIViewController {
    
    static var defaultTabBarItem: UITabBarItem {
        UITabBarItem(title: Constants.TabBar.campsDefaultText,
                     image: Constants.TabBar.campsDefaultImage,
                     tag: 2)
    }
    
    let campsTableView = CampsTableViewController()
    let controller = CampController()

    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) { view.backgroundColor = .systemBackground }
        
        view.addSubview(campsTableView.view)
        
        controller.getCamps { (camps) in
            DispatchQueue.main.async {
                self.campsTableView.camps = camps
                self.campsTableView.tableView.reloadData()
            }
        }
        
        updateViewConstraints()
    }

    override func updateViewConstraints() {
        super.updateViewConstraints()
        
        campsTableView.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            campsTableView.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            campsTableView.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            campsTableView.view.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            campsTableView.view.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
        ])
    }


}

