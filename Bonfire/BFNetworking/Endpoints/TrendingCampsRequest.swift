//
//  GetFriendsRequest.swift
//  BFNetworking
//
//  Created by James Dale on 22/6/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation
import BFCore

final public class TrendingCampsRequest: APIRequest {
    public typealias Response = [Camp]
    
    public let resource = "users/me/camps/lists/trending"
    
    public let body: Data? = nil

    public let method = "GET"
    
    public let authenticationType: AuthenticationType = .appAuth
    
    public init() {}
}
