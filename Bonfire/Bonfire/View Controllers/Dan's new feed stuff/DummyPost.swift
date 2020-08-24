//
//  DummyPost.swift
//  Bonfire
//
//  Created by Daniel Gauthier on 2020-08-19.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit

protocol Suggestable {
    var name: String { get }
    var image: UIImage { get }
    var color: UIColor { get }
    var suggestionDetail: String? { get }
}

struct DummyPost: Hashable {
    static func == (lhs: DummyPost, rhs: DummyPost) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    struct User: Suggestable {
        var name: String
        var image: UIImage
        var color: UIColor = UIColor(hex: "00BEFF")!
        var status: String?

        var suggestionDetail: String? { status }
    }

    struct Camp: Hashable, Suggestable {
        enum LiveType: Int, Codable {
            case audio
            case video
            case chat
        }

        var name: String
        var image: UIImage
        var color: UIColor = UIColor(hex: "387925")!
        var liveType: LiveType?

        var suggestionDetail: String? { "230 members" }
    }

    enum `Type`: Int, Codable {
        case liveRightNow
        case statusUpdate
        case suggestedFriend
        case post
    }

    var id: String
    var type: Type
    var expiry: Date?
    var people: [User]
    var camps: [Camp]


    static let testData: [DummyPost] = [
        DummyPost(id: "1", type: .liveRightNow, expiry: nil, people: [], camps: [
                    Camp(name: "Coffee Geeks", image: .dummyAvatar, liveType: .audio),
                    Camp(name: "Camera Gear", image: .dummyAvatar, liveType: .video),
                    Camp(name: "Lacroix Lovers", image: .dummyAvatar, liveType: .chat),
                    Camp(name: "Small Camp", image: .dummyAvatar, liveType: .audio),
                    Camp(name: "Medium Camp", image: .dummyAvatar, liveType: .video),
                    Camp(name: "Large Camp", image: .dummyAvatar, liveType: .chat)]),
        DummyPost(id: "3", type: .suggestedFriend, expiry: nil, people: [User(name: "Abayo Stevens", image: .dummyAvatar, status: "🥺 feeling loved")], camps: []),
        DummyPost(id: "2", type: .statusUpdate, expiry: nil, people: [User(name: "Austin Valleskey", image: .dummyAvatar, status: "🥳 ready to party")], camps: []),
        DummyPost(id: "4", type: .post, expiry: Date().advanced(by: 200), people: [User(name: "Daniel", image: .dummyAvatar)], camps: [Camp(name: "Coffee Geeks", image: .dummyAvatar)]),
        DummyPost(id: "5", type: .post, expiry: Date().advanced(by: 3800), people: [User(name: "Hugo", image: .dummyAvatar)], camps: [Camp(name: "Camera Gear", image: .dummyAvatar)]),
        DummyPost(id: "6", type: .post, expiry: Date().advanced(by: 3600 * 4), people: [User(name: "James", image: .dummyAvatar)], camps: [Camp(name: "Lacroix Lovers", image: .dummyAvatar)])
    ]
}

extension UIImage {
    static var dummyAvatar: UIImage {
        [UIImage(named: "Bird")!, UIImage(named: "Canal")!, UIImage(named: "City")!, UIImage(named: "Flowers")!, UIImage(named: "Pinwheel")!, UIImage(named: "Stream")!, UIImage(named: "Sunset")!, UIImage(named: "Tree")!].randomElement()!
    }
}
