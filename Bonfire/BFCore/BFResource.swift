//
//  BFResource.swift
//  BFCore
//
//  Created by James Dale on 30/6/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation

public enum BFResourceType: String, Codable {
    case camp
    case user
}

public protocol BFResource: Codable {
    var id: String? { get }
    var type: BFResourceType { get }
}
