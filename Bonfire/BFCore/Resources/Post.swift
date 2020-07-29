//
//  Post.swift
//  BFCore
//
//  Created by James Dale on 22/6/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation

public struct Post: BFResource {
    public let id: String?

    public let type: BFResourceType

    public let attributes: Attributes

    enum PostType {
        case text
        case image
        case audio
        case video
        case link
        case repost
    }
    
    public struct Attachments: Codable {
        public let media: [BFMediaAttachment]?
    }

    public class Attributes: Codable {
        public let message: String
        public let creator: User
        public let postedIn: Camp?
        public let parent: Post?
        public let summaries: BFSummaries?
        public let attachments: Attachments?

        enum CodingKeys: String, CodingKey {
            case message
            case creator
            case postedIn = "posted_in"
            case parent
            case summaries
            case attachments
        }
    }

}
