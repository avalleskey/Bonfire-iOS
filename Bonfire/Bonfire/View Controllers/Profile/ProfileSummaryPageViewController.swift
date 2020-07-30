//
//  ProfileSummaryPageView.swift
//  Bonfire
//
//  Created by James Dale on 31/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit

final class ProfileSummaryPageViewController: UIViewController {
    
    let imageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
    
    let primaryLabel: UILabel = {
        let label = UILabel()
        label.text = "303k camps  45 friends"
        return label
    }()
    
    let secondaryLabel: UILabel = {
        let label = UILabel()
        label.text = "340,203 notes"
        return label
    }()
    
}
