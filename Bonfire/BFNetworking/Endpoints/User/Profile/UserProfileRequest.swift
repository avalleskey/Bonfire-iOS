//
//  UserProfileRequest.swift
//  BFNetworking
//
//  Created by James Dale on 30/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation

public struct UserProfileRequest: APIRequest {
    public let resource: String

    public let body: Data? = nil

    public let queryItems: [URLQueryItem]? = nil

    public let method: String = "GET"

    public let authenticationType: AuthenticationType = .userAuth

    public typealias Response = UserProfileResponse
    
    public enum ProfileType {
        case me
        case otherUser(String)
    }

    public init(type: ProfileType) {
        switch type {
        case .me:
            self.resource = "users/me"
        case .otherUser(let userId):
            self.resource = "users/\(userId)"
        }
    }
}
