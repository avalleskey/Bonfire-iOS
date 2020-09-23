//
//  User.swift
//  BFCore
//
//  Created by James Dale on 22/6/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation

public enum UserStatus: String, Codable {
    case me = "me"
    case followed = "follows_me"
    case follows = "follows_them"
    case followsBoth = "follows_both"
    case blocked = "blocks_me"
    case blocks = "blocks_them"
    case blocksBoth = "blocks_both"
    case noRelation = "none"
}

public struct User: Identity {
    public init() {
        // anonymous user
        self.id = nil
        self.type = .user
        self.attributes = Attributes()
    }
    
    public init(id: String) {
        self.id = id
        self.type = .user
        self.attributes = Attributes()
    }
    
    public init(username: String) {
        self.id = nil
        self.type = .user
        self.attributes = Attributes(identifier: username)
    }
    
    public let id: String?
    
    public let type: BFResourceType
    
    public let attributes: Attributes

    public struct Attributes: Codable {
        public init() {
            self.identifier = ""
            self.displayName = ""
            self.bio = nil
            self.location = nil
            self.statusEmoji = nil
            self.statusString = nil
            self.color = "999999"
            self.createdAt = nil
            self.suspended = nil
            self.verified = nil
            self.media = nil
            self.summaries = nil
            self.context = nil
        }
        
        public init(identifier: String) {
            self.identifier = identifier
            self.displayName = "@\(identifier)"
            self.bio = nil
            self.location = nil
            self.statusEmoji = nil
            self.statusString = nil
            self.color = "999999"
            self.createdAt = nil
            self.suspended = nil
            self.verified = nil
            self.media = nil
            self.summaries = nil
            self.context = nil
        }
        
        public let identifier: String
        public let displayName: String
        public var shortDisplayName: String {
            String(displayName.split(separator: " ").first ?? "")
        }
        public let bio: String?
        public let location: UserLocation?
        public var statusEmoji: String? = "👀"
        public var statusString: String? = "looking for new friends"
        public let color: String
        public let createdAt: String?
        public let suspended: Bool?
        public let verified: Bool?
        public let media: BFMedia?
        public let summaries: UserSummaries?
        public let context: UserContext?
        
        enum CodingKeys: String, CodingKey {
            case identifier
            case displayName = "display_name"
            case bio
            case location
            case statusEmoji
            case statusString
            case color
            case createdAt = "created_at"
            case suspended
            case verified
            case media
            case summaries
            case context
        }
        
        public struct UserLocation: Codable {
            public let displayText: String
            
            enum CodingKeys: String, CodingKey {
                case displayText = "display_text"
            }
        }
        
        public struct UserSummaries: Codable {
            public let counts: Counts?
            
            public struct Counts: Codable {
                public let posts: Int?
                public let following: Int?
                public let camps: Int?
            }
        }
        
        public struct UserContext: Codable {
            public let me: ContextMe?
            public let camp: ContextCamp?
            
            public struct ContextCamp: Codable {
                public let status: CampStatus?
                public let membership: CampMembership?
                
                public struct CampMembership: Codable {
                    public let joinedAt: String?
                    public let role: CampMembershipRole?
                    
                    enum CodingKeys: String, CodingKey {
                        case joinedAt = "joined_at"
                        case role
                    }
                    
                    public struct CampMembershipRole: Codable {
                        public let type: CampRoleType?
                        public let assignedAt: String?
                        
                        enum CodingKeys: String, CodingKey {
                            case type
                            case assignedAt = "assigned_at"
                        }
                    }
                }
            }
            
            public struct ContextMe: Codable {
                public let follow: Follow?
                public let status: UserStatus?
                
                public struct Follow: Codable {
                    public let me: FollowAttributes?
                    public let them: FollowAttributes?
                    
                    public struct FollowAttributes: Codable {
                        public let createdAt: String?
                        
                        enum CodingKeys: String, CodingKey {
                            case createdAt = "created_at"
                        }
                    }
                }
            }
        }
    }
}
