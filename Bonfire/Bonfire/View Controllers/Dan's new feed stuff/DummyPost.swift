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
        struct Status {
            var emoji: String?
            var text: String?
        }
        var name: String
        var image: UIImage
        var color: UIColor = UIColor(hex: "00BEFF")!
        var status: Status?

        var suggestionDetail: String? {
            (status?.emoji ?? "") + " " + (status?.text ?? "")
        }
    }

    struct Camp: Hashable, Suggestable {
        enum LiveType: Int, Codable {
            case audio
            case video
            case chat

            var gradientColors: [UIColor] {
                switch self {
                case .audio:
                    return [.liveAudioTop, .liveAudioBottom]
                case .video:
                    return [.liveVideoTop, .liveVideoBottom]
                case .chat:
                    return [.liveChatTop, .liveChatBottom]
                }
            }
        }

        var name: String
        var image: UIImage
        var color: UIColor = UIColor(hex: "387925")!
        var liveType: LiveType?

        var suggestionDetail: String? { "230 members" }
    }

    struct Reply: Hashable {
        static func == (lhs: Reply, rhs: Reply) -> Bool {
            lhs.id == rhs.id
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }

        var id: String
        var user: User
        var message: String
    }

    enum `Type`: Int, Codable {
        case liveRightNow
        case statusUpdate
        case suggestion
        case post
    }

    var id: String
    var type: Type
    var expiry: Date?
    var people: [User]
    var camps: [Camp]
    var message: String?
    var attachments: [UIImage] = []
    var replies: [Reply] = []


    static let testData: [DummyPost] = [
        DummyPost(id: "1", type: .liveRightNow, expiry: nil, people: [], camps: [
                    Camp(name: "Coffee Geeks", image: .dummyAvatar, liveType: .audio),
                    Camp(name: "Camera Gear", image: .dummyAvatar, liveType: .video),
                    Camp(name: "Lacroix Lovers", image: .dummyAvatar, liveType: .chat),
                    Camp(name: "Small Camp", image: .dummyAvatar, liveType: .audio),
                    Camp(name: "Medium Camp", image: .dummyAvatar, liveType: .video),
                    Camp(name: "Large Camp", image: .dummyAvatar, liveType: .chat)]),
        DummyPost(id: "3", type: .suggestion, expiry: nil, people: [User(name: "Abayo Stevens", image: .dummyAvatar, status: User.Status(emoji: "🥺", text: "feeling loved"))], camps: []),
        DummyPost(id: "7", type: .suggestion, expiry: nil, people: [], camps: [Camp(name: "I should buy a boat", image: .dummyAvatar, color: .systemPink)]),
        DummyPost(id: "2", type: .statusUpdate, expiry: nil, people: [User(name: "Austin Valleskey", image: .dummyAvatar, status: User.Status(emoji: "🥳", text: "ready to party"))], camps: []),
        DummyPost(id: "4", type: .post, expiry: Date().advanced(by: 200), people: [User.dummyUser], camps: [Camp(name: "Coffee Geeks", image: .dummyAvatar)], message: "We're all different, but there's something kind of fantastic about that, isn't there?", replies: [
            Reply(id: "1", user: User.dummyUser, message: "This is a reply!"),
            Reply(id: "2", user: User.dummyUser, message: "Here is another slightly longer, more verbose reply.")
        ]),
        DummyPost(id: "5", type: .post, expiry: Date().advanced(by: 3800), people: [User(name: "Daniel Gauthier", image: .dummyAvatar)], camps: [Camp(name: "Wes Anderson Fans", image: .dummyAvatar)], message: "\"Vámanos, amigos,\" he whispered, and threw the busted leather flintcraw over the loose weave of the saddlecock. And they rode on in the friscalating dusklight.", attachments: [.dummyAvatar], replies: [
            Reply(id: "1", user: User.dummyUser, message: "Why a fox? Why not a horse, or a bald eagle? I'm saying this more as, like, existentialism, you know? Who am I?"),
            Reply(id: "2", user: User.dummyUser, message: "I’m supposed to be juggling 10 bowling pins engulfed in flames over my tail at this point, but you just have to imagine that part.")
        ]),
        DummyPost(id: "6", type: .post, expiry: Date().advanced(by: 3600 * 4), people: [User.dummyUser], camps: [Camp(name: "Lacroix Lovers", image: .dummyAvatar)], attachments: [.dummyAvatar, .dummyAvatar, .dummyAvatar, .dummyAvatar])
    ]
}

extension UIImage {
    static var dummyAvatar: UIImage {
        [UIImage(named: "Bird")!, UIImage(named: "Canal")!, UIImage(named: "City")!, UIImage(named: "Flowers")!, UIImage(named: "Pinwheel")!, UIImage(named: "Stream")!, UIImage(named: "Sunset")!, UIImage(named: "Tree")!].randomElement()!
    }
}

extension DummyPost.User {
    static var dummyUser: DummyPost.User {
        [DummyPost.User(name: "Hugo", image: .dummyAvatar), DummyPost.User(name: "James", image: .dummyAvatar), DummyPost.User(name: "Daniel", image: .dummyAvatar), DummyPost.User(name: "Austin Valleskey", image: .dummyAvatar), DummyPost.User(name: "Abayo Stevens", image: .dummyAvatar)].randomElement()!
    }
}
