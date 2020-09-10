//
//  MessagesViewController.swift
//  Bonfire
//
//  Created by Daniel Gauthier on 2020-09-08.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import BFCore
import Cartography
import UIKit

class MessagesViewController: BaseViewController {

    private let tableView: UITableView = .make(cellReuseIdentifier: ConversationCell.reuseIdentifier, cellClass: ConversationCell.self, allowsSelection: true, topOffset: NavigationBar.coreHeight, style: .grouped)
    private let loadingIndicator = UIActivityIndicatorView(style: .large, isAnimating: true, hidesWhenStopped: true)
    private let emptyStateMessageView = EmptyStateMessageView(title: "No messages yet")
    private var featuredUsers: [DummyPost.User] = []
    private var otherUsers: [DummyPost.User] = []
    private let controller = UserController()

    init() {
        super.init(navigationBar: NavigationBar(color: .systemBackground, title: "Messages"), scrollView: tableView)
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

        tableView.register(QuickAccessUserCollectionCell.self, forCellReuseIdentifier: QuickAccessUserCollectionCell.reuseIdentifier)
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

        // TODO: Would actually need to make call(s) to cloud here to get structured list of conversations.
        // For now, I'm just hard coding some dummy data to test the UI.

        featuredUsers = [
            .init(name: "Judy", image: .dummyAvatar, color: .systemIndigo, status: .init(emoji: "🤓", text: "Just coding."), isVerified: true, lastMessage: .init(text: "Hi", isRead: true, isOwnMessage: false, date: Date()), isSuggested: true),
            .init(name: "Edith", image: .dummyAvatar, color: .systemPink, status: .init(emoji: "👋", text: "Hello!"), lastMessage: .init(text: "Hi", isRead: true, isOwnMessage: false, date: Date())),
            .init(name: "Samuel", image: .dummyAvatar, color: .systemTeal, lastMessage: .init(text: "Hi", isRead: false, isOwnMessage: false, date: Date())),
            .init(name: "Chandler", image: .dummyAvatar, color: .systemOrange, lastMessage: .init(text: "Hi", isRead: true, isOwnMessage: false, date: Date()), isSuggested: true),
            .init(name: "Pascal", image: .dummyAvatar, color: .systemYellow, lastMessage: .init(text: "Hi", isRead: false, isOwnMessage: false, date: Date()))
        ]

        otherUsers = [
            DummyPost.User(name: "Austin Levy", image: .dummyAvatar, color: .systemIndigo, status: nil, isVerified: true, isTyping: true, lastMessage: nil, favoriteLevel: 3),
            DummyPost.User(name: "Terrell Green", image: .dummyAvatar, color: .systemPink, status: nil, isVerified: false, isTyping: false, lastMessage: .init(text: "Photo", isRead: false, isOwnMessage: false, date: Date().advanced(by: -60 * 20)), favoriteLevel: 2),
            DummyPost.User(name: "Shaun Gray", image: .dummyAvatar, color: .systemTeal, status: nil, isVerified: true, isTyping: false, lastMessage: .init(text: "hey man", isRead: false, isOwnMessage: false, date: Date().advanced(by: -60 * 60)), favoriteLevel: 1),
            DummyPost.User(name: "Amayo", image: .dummyAvatar, color: .systemOrange, status: .init(emoji: "🥳", text: "Ready to party"), isVerified: false, isTyping: false, lastMessage: .init(text: "Hey!", isRead: false, isOwnMessage: true, date: Date().advanced(by: -60 * 60 * 2)), favoriteLevel: 0),
            DummyPost.User(name: "Lindsay Logan", image: .dummyAvatar, color: .systemYellow, status: .init(emoji: "🙃", text: "Living in the upside-down"), isVerified: true, isTyping: false, lastMessage: DummyPost.User.Message(text: "Okay see you in a few!", isRead: true, isOwnMessage: false, date: Date().advanced(by: -3600 * 24 * 7)), favoriteLevel: 0)
        ]

        tableView.reloadData()
        UIView.animate(withDuration: 0.2, animations: {
            if self.otherUsers.isEmpty {
                self.emptyStateMessageView.alpha = 1.0
            } else {
                self.tableView.alpha = 1.0
            }
            self.loadingIndicator.alpha = 0.0
        }, completion: nil)
    }
}

extension MessagesViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if featuredUsers.count > 0 {
            return otherUsers.count + 1
        } else {
            return otherUsers.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if featuredUsers.count > 0 {
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: QuickAccessUserCollectionCell.reuseIdentifier, for: indexPath) as! QuickAccessUserCollectionCell
                cell.users = featuredUsers
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: ConversationCell.reuseIdentifier, for: indexPath) as! ConversationCell
                cell.user = otherUsers[indexPath.row - 1]
                return cell
            }
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: ConversationCell.reuseIdentifier, for: indexPath) as! ConversationCell
            cell.user = otherUsers[indexPath.row]
            return cell
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if featuredUsers.count > 0 && indexPath.row == 0 {
            return 120 * CGFloat((featuredUsers.count / 3) + 1) + 8 + 16 + 16
        }
        return UITableView.automaticDimension
    }
}

extension MessagesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("select")
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if featuredUsers.count > 0 && indexPath.row == 0 { return nil }
        return indexPath
    }
}
