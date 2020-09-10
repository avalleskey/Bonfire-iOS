//
//  CampsViewController.swift
//  Bonfire
//
//  Created by Daniel Gauthier on 2020-09-03.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import BFCore
import Cartography
import UIKit

class CampsViewController: BaseViewController {

    private let tableView: UITableView = .make(cellReuseIdentifier: CampCell.reuseIdentifier, cellClass: CampCell.self, allowsSelection: true, topOffset: NavigationBar.coreHeight, style: .grouped)
    private let loadingIndicator = UIActivityIndicatorView(style: .large, isAnimating: true, hidesWhenStopped: true)
    private let emptyStateMessageView = EmptyStateMessageView(title: "No Camps yet", subtitle: "Start one by tapping + below!")
    private var featuredCamps: [Camp] = []
    private var otherCamps: [Camp] = []
    private let controller = CampController()

    init() {
        super.init(navigationBar: NavigationBar(color: .systemBackground, title: "Camps"), scrollView: tableView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setUpTableView()
        setUpLoadingIndicator()
        setUpEmptyStateMessageView()
        refreshData()
    }

    private func setUpTableView() {
        view.addSubview(tableView)
        constrain(tableView) {
            $0.top == $0.superview!.safeAreaLayoutGuide.top
            $0.leading == $0.superview!.leading
            $0.trailing == $0.superview!.trailing
            $0.bottom == $0.superview!.bottom
        }

        tableView.alpha = 0
        tableView.dataSource = self
        tableView.delegate = self
    }

    private func setUpLoadingIndicator() {
        view.addSubview(loadingIndicator)
        constrain(loadingIndicator) {
            $0.centerX == $0.superview!.centerX
            $0.centerY == $0.superview!.centerY + (NavigationBar.coreHeight / 2)
        }
    }

    private func setUpEmptyStateMessageView() {
        view.addSubview(emptyStateMessageView)
        constrain(emptyStateMessageView) {
            $0.centerX == $0.superview!.centerX
            $0.leading >= $0.superview!.leading + 16
            $0.trailing <= $0.superview!.trailing - 16
            $0.centerY == $0.superview!.centerY + (NavigationBar.coreHeight / 2)
        }

        emptyStateMessageView.alpha = 0
    }

    private func refreshData() {
        controller.getCamps { camps in
            DispatchQueue.main.async {
                // TODO: I'm just artificially splitting camps into two sections here for now
                self.featuredCamps = Array(camps.prefix(5))
                self.otherCamps = Array(camps.suffix(from: 5))
                self.tableView.reloadData()
                UIView.animate(withDuration: 0.2, animations: {
                    if camps.isEmpty {
                        self.emptyStateMessageView.alpha = 1.0
                    } else {
                        self.tableView.alpha = 1.0
                    }
                    self.loadingIndicator.alpha = 0.0
                }, completion: nil)
            }
        }
    }
}

extension CampsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return featuredCamps.count
        } else {
            return otherCamps.count
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int { 2 }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CampCell.reuseIdentifier, for: indexPath) as! CampCell

        if indexPath.section == 0 {
            cell.camp = featuredCamps[indexPath.row]
            cell.isFeaturedCamp = true
            cell.displayType = .onlineCount
        } else {
            cell.camp = otherCamps[indexPath.row]
            cell.isFeaturedCamp = false
            switch indexPath.row % 4 {
            case 0: cell.displayType = .creator
            case 1: cell.displayType = .liveChat
            case 2: cell.displayType = .newFires
            case 3: cell.displayType = .onlineCount
            default: break
            }
        }

        return cell
    }
}

extension CampsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section == 1 else { return nil }
        let view = UIView()
        let titleLabel = UILabel(size: 18, weight: .heavy, color: .secondaryGray, multiline: false, text: "Other Camps")
        view.addSubview(titleLabel)
        constrain(titleLabel) {
            $0.leading == $0.superview!.leading + 12
            $0.trailing == $0.superview!.trailing - 12
            $0.bottom == $0.superview!.bottom - 12
        }
        return view
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        section == 1 ? 48 : 0
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("select")
    }
}
