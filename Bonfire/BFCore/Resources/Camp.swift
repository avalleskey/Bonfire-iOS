//
//  Camp.swift
//  BFCore
//
//  Created by James Dale on 22/6/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation

public struct Camp: Codable {
    public let id: String
    public let attributes: Attributes
    
    public struct Attributes: Codable {
        public let title: String
        public let description: String
        public let color: String
        public let createdAt: Date?
        public let suspended: Bool
        public let verified: Bool
        public let `private`: Bool
        public let nsfw: Bool
        public let media: BFMedia?
    }
    
    //media
    
}
