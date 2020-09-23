//
//  ProfileSheetViewController.swift
//  Bonfire
//
//  Created by Austin Valleskey on 9/22/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import BFCore
import UIKit

final class ProfileSheetViewController: SheetFeedViewController {
    private let controller = StreamController()
    
    private let userId: String?
    init(userId: String) {
        self.userId = userId
        super.init()
        
        refreshData()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func refreshData() {
        if let userId = userId {
            controller.getStream(userId: userId) { posts in
                DispatchQueue.main.async {
                    self.posts = posts
                    self.tableView.reloadData()
                    self.tableView.transform = CGAffineTransform(translationX: 0, y: 12)
                    UIView.animate(withDuration: 0.2, animations: {
                        if posts.isEmpty {
                            self.emptyStateMessageView.alpha = 1.0
                        } else {
                            self.tableView.alpha = 1.0
                            self.tableView.transform = .identity
                        }
                        self.loadingIndicator.alpha = 0.0
                        self.loadingIndicator.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
                    }, completion: nil)
                }
            }
        }
    }
}
