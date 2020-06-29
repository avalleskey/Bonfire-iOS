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
                     tag: 0)
    }
    
    let campsTableView = CampsTableViewController()
    let controller = CampController()
    
    let addCampBtn: UIButton = {
        let btn = UIButton()
        btn.setTitle("Add Camp", for: .normal)
        btn.setTitleColor(.black, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        btn.titleLabel?.font = btn.titleLabel?.font.rounded()
        btn.setImage(UIImage(named: "AddFriends"), for: .normal)
        btn.titleEdgeInsets = .init(top: 0, left: 8, bottom: 0, right: -8)
        btn.contentEdgeInsets = .init(top: 12, left: 16, bottom: 12, right: 16)
        btn.backgroundColor = .white
        btn.layer.shadowColor = UIColor.black.cgColor
        btn.layer.shadowOpacity = 0.12
        btn.layer.shadowOffset = .init(width: 0, height: 2)
        btn.layer.cornerRadius = 20
        btn.layer.shadowRadius = 6
        return btn
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) { view.backgroundColor = .systemBackground }
        
        view.addSubview(campsTableView.view)
        view.addSubview(addCampBtn)
        
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
        addCampBtn.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            campsTableView.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            campsTableView.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            campsTableView.view.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            campsTableView.view.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
        ])
        
        NSLayoutConstraint.activate([
            addCampBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            addCampBtn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                                                  constant: -16),
        ])
    }


}

