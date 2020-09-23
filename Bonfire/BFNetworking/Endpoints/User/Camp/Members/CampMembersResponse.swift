//
//  UserProfileResponse.swift
//  BFNetworking
//
//  Created by James Dale on 30/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import BFCore
import Foundation

public struct CampMembersResponse: Decodable {
    public let data: [User]
}
