//
//  User.swift
//  BFCore
//
//  Created by James Dale on 22/6/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation

public struct User: Identity {
    public let attributes: Attributes

    public let type: BFResourceType

    public let id: String?

    public struct Attributes: Codable {
        public let identifier: String
        public let display_name: String
        public var shortDisplayName: String {
            String(display_name.split(separator: " ").first ?? "")
        }
        public let color: String
        public let createdAt: Date?
        public let suspended: Bool?
        public let verified: Bool?
        public let media: BFMedia?
    }
}
