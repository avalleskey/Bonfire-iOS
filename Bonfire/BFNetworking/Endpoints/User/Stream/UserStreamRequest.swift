//
//  UserStreamRequest.swift
//  BFNetworking
//
//  Created by James Dale on 5/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation

public struct UserStreamRequest: APIRequest {
    public let resource: String

    public let body: Data? = nil

    public let queryItems: [URLQueryItem]? = nil

    public let method: String = "GET"

    public let authenticationType: AuthenticationType = .userAuth
    
    public enum ProfileType {
        case me
        case otherUser(String)
    }

    public typealias Response = UserStreamResponse

    public init(type: ProfileType) {
        switch type {
        case .me:
            self.resource = "streams/me"
        case .otherUser(let userId):
            self.resource = "streams/\(userId)"
        }
    }
}
