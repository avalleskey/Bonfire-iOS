//
//  Post.swift
//  BFCore
//
//  Created by James Dale on 22/6/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation

private let expiryFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale.current
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
    return formatter
}()

public struct Post: BFResource, Hashable {
    public static func == (lhs: Post, rhs: Post) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public let id: String?

    public let type: BFResourceType

    public let attributes: Attributes
    
    public var isExpired: Bool {
        var expired: Bool = true
        if let createdAt = self.attributes.createdAt {
            let expiry: Date = (expiryFormatter.date(from: createdAt)?.addingTimeInterval(60 * 60 * 24))!
            let secondsLeft = Int(expiry.timeIntervalSince(Date()))
            expired = secondsLeft < 0
        }
        return expired
    }

    enum PostType {
        case text
        case image
        case audio
        case video
        case link
        case repost
    }

    public class Attributes: Codable {
        public init() {
            self.createdAt = nil
            self.message = nil
            self.creator = nil
            self.postedIn = nil
            self.parent = nil
            self.summaries = nil
            self.attachments = nil
            self.context = nil
        }
        
        public let createdAt: String?
        public let message: String?
        public let creator: User?
        public let postedIn: Camp?
        public let parent: Post?
        public let summaries: BFSummaries?
        public let attachments: PostAttachments?
        public let context: PostContext?

        enum CodingKeys: String, CodingKey {
            case createdAt = "created_at"
            case message
            case creator
            case postedIn = "posted_in"
            case parent
            case summaries
            case attachments
            case context
        }
        
        public struct PostAttachments: Codable {
            public let media: [BFMediaAttachment]?
            public let link: BFLinkAttachment?
        }
        
        public struct PostContext: Codable {
            public let post: PostContextPost?
            
            public struct PostContextPost: Codable {
                public let vote: PostVote?
                
                public struct PostVote: Codable {
                    public let createdAt: String
                    
                    enum CodingKeys: String, CodingKey {
                        case createdAt = "created_at"
                    }
                }
            }
        }
    }

}
