//
//  UserProfileRequest.swift
//  BFNetworking
//
//  Created by James Dale on 30/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation

public struct CampMembersRequest: APIRequest {
    public let resource: String

    public let body: Data? = nil

    public let queryItems: [URLQueryItem]? = nil

    public let method: String = "GET"

    public let authenticationType: AuthenticationType = .userAuth

    public typealias Response = CampMembersResponse

    public init(campId: String) {
        self.resource = "camps/\(campId)/members"
    }
}
