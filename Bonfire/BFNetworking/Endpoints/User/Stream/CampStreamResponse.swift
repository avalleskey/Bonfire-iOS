//
//  CampStreamResponse.swift
//  BFNetworking
//
//  Created by Austin Valleskey on 5/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import BFCore
import Foundation

public struct CampStreamResponse: Decodable {
    public let data: [Section]
}
