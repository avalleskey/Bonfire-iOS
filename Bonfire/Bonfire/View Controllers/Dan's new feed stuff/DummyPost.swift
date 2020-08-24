//
//  DummyPost.swift
//  Bonfire
//
//  Created by Daniel Gauthier on 2020-08-19.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit

struct DummyPost: Hashable {
    static func == (lhs: DummyPost, rhs: DummyPost) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    enum `Type`: Int, Codable {
        case liveRightNow
        case statusUpdate
        case suggestedFriend
        case post
    }

    struct Creator {
        var name: String
        var image: UIImage
    }

    struct Camp {
        var name: String
        var image: UIImage
    }

    var id: String
    var type: Type
    var expiry: Date?
    var creator: Creator?
    var camp: Camp?


    static let testData: [DummyPost] = [
        DummyPost(id: "1", type: .liveRightNow, expiry: nil, creator: nil, camp: nil),
        DummyPost(id: "2", type: .statusUpdate, expiry: nil, creator: Creator(name: "Austin Valleskey", image: .dummyAvatar), camp: nil),
        DummyPost(id: "3", type: .suggestedFriend, expiry: nil, creator: nil, camp: nil),
        DummyPost(id: "4", type: .post, expiry: Date().advanced(by: 200), creator: Creator(name: "Daniel", image: .dummyAvatar), camp: Camp(name: "Coffee Geeks", image: .dummyAvatar)),
        DummyPost(id: "5", type: .post, expiry: Date().advanced(by: 3800), creator: Creator(name: "Hugo", image: .dummyAvatar), camp: Camp(name: "Camera Gear", image: .dummyAvatar)),
        DummyPost(id: "6", type: .post, expiry: Date().advanced(by: 3600 * 4), creator: Creator(name: "James", image: .dummyAvatar), camp: Camp(name: "Lacroix Lovers", image: .dummyAvatar))
    ].shuffled()
}

extension UIImage {
    static var dummyAvatar: UIImage {
        [UIImage(named: "DummyAvatar")!, UIImage(named: "DefaultCampAvatar_dark")!, UIImage(named: "Austin")!].randomElement()!
    }
}
