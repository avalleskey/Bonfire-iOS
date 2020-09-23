//
//  CampStreamRequest.swift
//  BFNetworking
//
//  Created by Austin Valleskey on 5/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation

public struct CampStreamRequest: APIRequest {
    public let resource: String

    public let body: Data? = nil

    public let queryItems: [URLQueryItem]? = nil

    public let method: String = "GET"

    public let authenticationType: AuthenticationType = .userAuth

    public typealias Response = CampStreamResponse

    public init(campId: String) {
        self.resource = "camps/\(campId)/stream"
    }
}
