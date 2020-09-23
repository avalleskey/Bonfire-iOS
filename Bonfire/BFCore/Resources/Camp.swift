//
//  Camp.swift
//  BFCore
//
//  Created by James Dale on 22/6/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation

public enum CampStatus: String, Codable {
    case invited
    case requested
    case member
    case left
    case blocked
    case none
}

public enum CampPermissionContentType: String, Codable {
    case text
    case img = "media/img"
    case gif = "media/gif"
    case video = "media/video"
    case mediaText = "media/text"
}

public enum CampRoleType: String, Codable {
    case admin
    case moderator
    case member
}

public struct Camp: Codable, Hashable {
    public static func == (lhs: Camp, rhs: Camp) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public init() {
        self.id = nil
        self.type = .camp
        self.attributes = Attributes()
    }
    
    public init(id: String) {
        self.id = id
        self.type = .camp
        self.attributes = Attributes()
    }
    
    public init(camptag: String) {
        self.id = nil
        self.type = .camp
        self.attributes = Attributes(identifier: camptag)
    }

    public let id: String?
    
    public let type: BFResourceType
    
    public let attributes: Attributes

    public struct Attributes: Codable {
        public init() {
            self.title = ""
            self.description = nil
            self.identifier = nil
            self.color = "999999"
            self.createdAt = nil
            self.suspended = nil
            self.verified = nil
            self.private = nil
            self.nsfw = nil
            self.media = nil
            self.summaries = nil
            self.context = nil
        }
        
        public init(identifier: String) {
            self.title = "#\(identifier)"
            self.description = nil
            self.identifier = identifier
            self.color = "999999"
            self.createdAt = nil
            self.suspended = nil
            self.verified = nil
            self.private = nil
            self.nsfw = nil
            self.media = nil
            self.summaries = nil
            self.context = nil
        }
        
        public let title: String
        public let description: String?
        public let identifier: String?
        public let color: String
        public let createdAt: String?
        public let suspended: Bool?
        public let verified: Bool?
        public let `private`: Bool?
        public let nsfw: Bool?
        public let media: BFMedia?
        public let summaries: CampSummaries?
        public let context: CampContext?
        
        enum CodingKeys: String, CodingKey {
            case title
            case description
            case identifier
            case color
            case createdAt = "created_at"
            case suspended
            case verified
            case `private`
            case nsfw
            case media
            case summaries
            case context
        }
        
        public struct CampSummaries: Codable {
            public let counts: Counts?
            public let members: [User]?
            
            public struct Counts: Codable {
                public let members: Int?
                public let posts: Int?
                public let icebreakers: Int?
                public let posts24hr: Int?
                public let postsNewForYou: Int?
                public let score: Int?
                public let scoreIndex: Int?
                
                enum CodingKeys: String, CodingKey {
                    case members
                    case posts
                    case icebreakers
                    case posts24hr = "posts_24hr"
                    case postsNewForYou = "posts_new_foryou"
                    case score
                    case scoreIndex = "score_index"
                }
            }
        }
        
        public struct CampContext: Codable {
            public let camp: ContextCamp?
            
            public struct ContextCamp: Codable {
                public let status: CampStatus?
                public let membership: CampMembership?
                public let permissions: CampPermissions?
                
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
                
                public struct CampPermissions: Codable {
                    public let post: [CampPermissionContentType]?
                    public let assign: [CampRoleType]?
                    public let update: Bool?
                    public let delete: Bool?
                    public let members: CampPermissionsMembers?
                    
                    public struct CampPermissionsMembers: Codable {
                        public let invite: Bool?
                        public let approve: Bool?
                        public let remove: Bool?
                    }
                }
            }
        }
    }
}
