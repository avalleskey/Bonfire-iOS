//
//  GetFriendsRequest.swift
//  BFNetworking
//
//  Created by James Dale on 22/6/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import BFCore
import Foundation

final public class MyCampsRequest: APIRequest {
    public typealias Response = MyCampsResponse

    public let resource = "users/me/camps"

    public let body: Data? = nil

    public let queryItems: [URLQueryItem]? = nil

    public let method = "GET"

    public let authenticationType: AuthenticationType = .userAuth

    public init() {}
}
