//
//  Section.swift
//  BFCore
//
//  Created by James Dale on 5/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation

public struct Section: BFResource {
    public let id: String?
    
    public let type: BFResourceType
    
    public let attributes: Attributes
    
    public struct Attributes: Codable {
        public let posts: [Post]
    }
    
}
