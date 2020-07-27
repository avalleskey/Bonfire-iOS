//
//  UserActivity.swift
//  BFCore
//
//  Created by Austin Valleskey on 24/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation

public enum UserActivityType: Int, Codable {
    case unknown = 0
    
    // Result of a user action
    case follow = 1
    case userAcceptedAccess = 2
    case userPosted = 6
    case userPostedCamp = 9
    
    // Result of an action in a joined camp
    case campAccessRequest = 3
    case campInvite = 7
    
    // Result of action on user's post
    case postReply = 4
    case postDefaultReaction = 5
    case postMention = 8
}

public struct UserActivity: BFResource {
    public let id: String?

    public let type: BFResourceType

    public let attributes: Attributes

    public class Attributes: Codable {
        public let type: Int
        public let createdAt: String
        public let read: Bool
        
        public let title: UserActivityTitle?
        public let target: UserActivityTarget?
        
        public let actioner: User?
        
        public let post: Post?
        public let replyPost: Post?
        public let camp: Camp?
        
        enum CodingKeys: String, CodingKey {
            case type
            case createdAt = "created_at"
            case read
            
            case title
            case target
            
            case actioner
            
            case post
            case replyPost = "reply_post"
            case camp
        }
    }

}
