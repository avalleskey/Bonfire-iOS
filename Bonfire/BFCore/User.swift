//
//  User.swift
//  BFCore
//
//  Created by James Dale on 22/6/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation

public struct User: Identity {
    public let displayName: String
    
    public init(name: String) {
        self.displayName = name
    }
}
