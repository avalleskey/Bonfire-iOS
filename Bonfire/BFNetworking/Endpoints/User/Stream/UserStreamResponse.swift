//
//  UserStreamResponse.swift
//  BFNetworking
//
//  Created by James Dale on 5/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation
import BFCore

public struct UserStreamResponse: Decodable {
    public let data: [Section]
}
