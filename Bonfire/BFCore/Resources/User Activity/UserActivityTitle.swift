//
//  UserActivityTitle.swift
//  BFCore
//
//  Created by Austin Valleskey on 7/26/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation

public struct UserActivityTitle: Codable {
    public let title: String
    public let entities: [BFEntity]?
}
