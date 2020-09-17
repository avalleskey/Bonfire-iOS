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

class MessagesListViewController: BaseViewController {

    private let tableView: UITableView = .make(cellReuseIdentifier: ConversationCell.reuseIdentifier, cellClass: ConversationCell.self, allowsSelection: true, topOffset: NavigationBar.coreHeight, style: .grouped)
    private let loadingIndicator = UIActivityIndicatorView(style: .whiteLarge, color: .secondaryText, isAnimating: true, hidesWhenStopped: true)
    private let emptyStateMessageView = EmptyStateMessageView(title: "No messages yet")
    private var featuredUsers: [DummyPost.User] = []
    private var otherUsers: [DummyPost.User] = []
    private let controller = UserController()

    init() {
        super.init(navigationBar: NavigationBar(color: Constants.Color.systemBackground, title: "Messages"), scrollView: tableView, floatingButton: BFFloatingButton(icon: UIImage(named: "NewMessageIcon")))
        
        floatingButton?.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Constants.Color.systemBackground
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
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 72
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
            .init(name: "Judy", image: .dummyAvatar, color: .liveAudioBottom, status: .init(emoji: "🤓", text: "Just coding."), isVerified: true, lastMessage: .init(text: "Hi", isRead: true, isOwnMessage: false, date: Date()), isSuggested: true),
            .init(name: "Edith", image: .dummyAvatar, color: .liveAudioTop, status: .init(emoji: "👋", text: "Hello!"), lastMessage: .init(text: "Hi", isRead: true, isOwnMessage: false, date: Date())),
            .init(name: "Samuel", image: .dummyAvatar, color: .liveBottom, lastMessage: .init(text: "Hi", isRead: false, isOwnMessage: false, date: Date())),
            .init(name: "Chandler", image: .dummyAvatar, color: .liveTop, lastMessage: .init(text: "Hi", isRead: true, isOwnMessage: false, date: Date()), isSuggested: true),
            .init(name: "Pascal", image: .dummyAvatar, color: .liveChatTop, lastMessage: .init(text: "Hi", isRead: false, isOwnMessage: false, date: Date()))
        ]

        otherUsers = [
            DummyPost.User(name: "Austin Levy", image: .dummyAvatar, color: .liveChatBottom, status: nil, isVerified: true, isTyping: true, lastMessage: nil, favoriteLevel: 3),
            DummyPost.User(name: "Terrell Green", image: .dummyAvatar, color: .liveVideoTop, status: nil, isVerified: false, isTyping: false, lastMessage: .init(text: "Photo", isRead: false, isOwnMessage: false, date: Date().addingTimeInterval(-60 * 20)), favoriteLevel: 2),
            DummyPost.User(name: "Shaun Gray", image: .dummyAvatar, color: .liveVideoBottom, status: nil, isVerified: true, isTyping: false, lastMessage: .init(text: "hey man", isRead: false, isOwnMessage: false, date: Date().addingTimeInterval(-60 * 60)), favoriteLevel: 1),
            DummyPost.User(name: "Amayo", image: .dummyAvatar, color: .liveAudioTop, status: .init(emoji: "🥳", text: "Ready to party"), isVerified: false, isTyping: false, lastMessage: .init(text: "Hey!", isRead: false, isOwnMessage: true, date: Date().addingTimeInterval(-60 * 60 * 2)), favoriteLevel: 0),
            DummyPost.User(name: "Lindsay Logan", image: .dummyAvatar, color: .liveBottom, status: .init(emoji: "🙃", text: "Living in the upside-down"), isVerified: true, isTyping: false, lastMessage: DummyPost.User.Message(text: "Okay see you in a few!", isRead: true, isOwnMessage: false, date: Date().addingTimeInterval(-3600 * 24 * 7)), favoriteLevel: 0)
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

extension MessagesListViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return featuredUsers.count > 0 ? 1 : 0
        } else if section == 1 {
            return otherUsers.count
        }
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: QuickAccessUserCollectionCell.reuseIdentifier, for: indexPath) as! QuickAccessUserCollectionCell
            cell.users = featuredUsers
            cell.delegate = self
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: ConversationCell.reuseIdentifier, for: indexPath) as! ConversationCell
            cell.user = otherUsers[indexPath.row]
            cell.separatorView.isHidden = (indexPath.row == otherUsers.count - 1)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
}

extension MessagesListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let messageViewController = MessageViewController()
        navigationController?.pushViewController(messageViewController, animated: true)
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if indexPath.section == 0 { return nil }
        return indexPath
    }
}


extension MessagesListViewController: QuickAccessUserCollectionCellDelegate {
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let messageViewController = MessageViewController()
        navigationController?.pushViewController(messageViewController, animated: true)
    }
}

extension MessagesListViewController: BFFloatingButtonDelegate {
    func floatingButtonTapped() {
        print("new message")
    }
}
