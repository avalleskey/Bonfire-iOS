//
//  CampViewController.swift
//  Bonfire
//
//  Created by James Dale on 31/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import BFCore
import UIKit
import Cartography

final class CampViewController: SplitViewController<CampHeaderView, CampSheetViewController> {
    
    private let camps = CampController()
    
    var camp: Camp? {
        didSet {
            DispatchQueue.main.async {
                self.campUpdated()
            }
        }
    }

    init(camp: Camp?) {
        self.camp = camp
        super.init(headerView: CampHeaderView(), sheetViewController: CampSheetViewController(campId: camp?.id ?? camp?.attributes.identifier ?? ""), navigationBar: NavigationBar(color: Constants.Color.navigationBar, leftButtonType: .back, rightButtonType: .more, title: "", subtitle: ""), scrollView: nil, floatingButton: BFFloatingButton(icon: UIImage(named: "ComposeIcon"), background: .color(camp?.attributes.uiColor)))
        
        floatingButton?.delegate = self
        
        navigationBar.leftButtonAction = {
            self.navigationController?.popViewController(animated: true)
        }
        navigationBar.rightButtonAction = {
            let options = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            let report = UIAlertAction(
                title: "Report ✋", style: .destructive,
                handler: { (action) in
                    
                })
            options.addAction(report)

            options.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(options, animated: true, completion: nil)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateWithColor(camp?.attributes.color, animated: false)
    }
    
    override func setUpHeaderView() {
        super.setUpHeaderView()
        headerView.camp = camp
        headerView.delegate = self
    }
    
    override func setUpSheet() {
        super.setUpSheet()
        
        sheetViewController.tableView.contentInset.bottom = 64 + (12 * 2)
        
        sheetViewController.navigationBar.rightButtonAction = {
            var message: String?
            if let displayName = self.camp?.attributes.title {
                message = "When there are new fires in \(displayName), notify me"
            }
            let options = UIAlertController(title: nil, message: message, preferredStyle: .actionSheet)

            let checkString = " ✓"
            let viewProfile = UIAlertAction(
                title: "Always\(false ? checkString : "")", style: .default,
                handler: { (action) in
                    
                })
            options.addAction(viewProfile)
            
            let leave = UIAlertAction(
                title: "Sometimes\(true ? checkString : "")", style: .default,
                handler: { (action) in
                    
                })
            options.addAction(leave)
            
            let report = UIAlertAction(
                title: "Never\(false ? checkString : "")", style: .default,
                handler: { (action) in
                    
                })
            options.addAction(report)

            options.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(options, animated: true, completion: nil)
        }
    }
    
    override func loadData() {
        if let campId = camp?.id {
            self.camps.getCamp(campId: campId) { camp in
                DispatchQueue.main.async {
                    self.camp = camp
                }
            }
        }
    }
    
    private func campUpdated() {
        headerView.camp = camp
        updateWithColor(camp?.attributes.color, animated: true)
        navigationBar.title = camp?.attributes.title ?? nil
        if let memberCount = camp?.attributes.summaries?.counts?.members {
            navigationBar.subtitle = "\(memberCount) camper\(memberCount != 1 ? "s" : "")"
        }
        
        if sheetState == .collapsed {
            self.sheetTopConstraint?.constant = self.collapsedHeight
            
            UIView.animate(
                withDuration: 0.4,
                delay: 0,
                usingSpringWithDamping: 0.9,
                initialSpringVelocity: 3,
                options: [.curveEaseInOut],
                animations: {
                    self.view.layoutIfNeeded()
                })
        }
    }
}

extension CampViewController: BFFloatingButtonDelegate {
    func floatingButtonTapped() {
        let composeViewController = ComposeViewController()
        self.present(composeViewController, customPresentationType: .present)
    }
}

extension CampViewController: CampHeaderViewDelegate {
    func openCampMembers(camp: Camp) {
        let campMembersViewController = CampMembersViewController(camp: camp)
        self.navigationController?.pushViewController(campMembersViewController, animated: true)
    }
}
