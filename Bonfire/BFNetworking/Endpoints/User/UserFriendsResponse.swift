//
//  UserFriendsResponse.swift
//  BFNetworking
//
//  Created by James Dale on 30/6/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation
import BFCore

public struct UserFriendsResponse: Codable {
    public let data: [User]
}
