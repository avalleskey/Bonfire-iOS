//
//  GetFriendsRequest.swift
//  BFNetworking
//
//  Created by James Dale on 22/6/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation
import BFCore

final public class GetFriendsRequest: APIRequest {
    public typealias Response = [User]
    
    public let resource = "friends"
    
    public let body: Data? = nil

    public let method = "GET"
}
