//
//  CampSheetViewController.swift
//  Bonfire
//
//  Created by Austin Valleskey on 9/22/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import BFCore
import UIKit

final class CampSheetViewController: SheetFeedViewController {
    private let controller = StreamController()
    
    private let campId: String?
    init(campId: String) {
        self.campId = campId
        super.init(title: "Campfire")
        
        refreshData()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func refreshData() {
        if let campId = campId {
            controller.getStream(campId: campId) { posts in
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
