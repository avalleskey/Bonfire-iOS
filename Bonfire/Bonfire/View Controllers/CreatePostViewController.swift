//
//  CreatePostViewController.swift
//  Bonfire
//
//  Created by James Dale on 21/6/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation
import UIKit

final class CreatePostViewController: UIViewController {

    static var defaultTabBarItem: UITabBarItem {
        UITabBarItem(
            title: "",
            image: Constants.TabBar.composeDefaultImage,
            tag: 0)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) { view.backgroundColor = .systemGreen }
    }

}
