//
//  UserNotificationsRequest.swift
//  BFNetworking
//
//  Created by Austin Valleskey on 24/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import BFCore
import Foundation

public struct UserNotificationsRequest: APIRequest {
    public typealias Response = UserNotificationsResponse

    public let resource = "users/me/notifications"

    public let body: Data? = nil

    public let queryItems: [URLQueryItem]? = nil

    public let method = "GET"

    public let authenticationType: AuthenticationType = .userAuth

    public init() {}
}
