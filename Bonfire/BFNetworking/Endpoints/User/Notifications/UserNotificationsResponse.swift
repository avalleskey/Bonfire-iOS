//
//  UserNotificationsResponse.swift
//  BFNetworking
//
//  Created by James Dale on 30/6/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import BFCore
import Foundation

public struct UserNotificationsResponse: Codable {
    public let data: [UserActivity]
}
