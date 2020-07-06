//
//  CampDetailViewController.swift
//  Bonfire
//
//  Created by James Dale on 6/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation
import UIKit

final class CampDetailViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) { view.backgroundColor = .systemTeal }
        hero.isEnabled = false
    }

}

