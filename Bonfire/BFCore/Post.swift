//
//  Post.swift
//  BFCore
//
//  Created by James Dale on 22/6/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation

public struct Post: Codable {
    
    enum PostType {
        case text
        case image
        case audio
        case video
        case link
        case repost
    }
    
    public init(title: String) {
        self.title = title
    }
    
    
    let title: String
    
    
    
}
