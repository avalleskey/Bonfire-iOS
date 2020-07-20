//
//  OAuth.swift
//  BFNetworking
//
//  Created by James Dale on 12/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import BFCore
import Foundation

final public class OAuthRequest: APIRequest {
    public typealias Response = OAuthResponse

    public let resource = "accounts/validate/username"

    public let body: Data?

    public let queryItems: [URLQueryItem]? = nil

    public let method = "POST"

    public let authenticationType: AuthenticationType = .appAuth

    public init(body: OAuthRequestBody) {
        let encoder = JSONEncoder()
        self.body = try? encoder.encode(body)
    }
}
