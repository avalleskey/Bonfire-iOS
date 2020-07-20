//
//  UserStreamRequest.swift
//  BFNetworking
//
//  Created by James Dale on 5/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation

public struct UserStreamRequest: APIRequest {
    public let resource: String = "streams/me"

    public let body: Data? = nil

    public let queryItems: [URLQueryItem]? = nil

    public let method: String = "GET"

    public let authenticationType: AuthenticationType = .userAuth

    public typealias Response = UserStreamResponse

    public init() {}
}
