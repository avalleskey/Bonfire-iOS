//
//  UserFriendsRequest.swift
//  BFNetworking
//
//  Created by James Dale on 30/6/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation
import BFCore

final public class UserFriendsRequest: APIRequest {
    public typealias Response = UserFriendsResponse
    
    public let resource = "users/me/friends"
    
    public let body: Data? = nil
    
    public let queryItems: [URLQueryItem]? = nil

    public let method = "GET"
    
    public let authenticationType: AuthenticationType = .userAuth
    
    public init() {}
}
