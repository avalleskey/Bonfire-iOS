//
//  CampCounts.swift
//  Pulse
//
//  Created by James Dale on 15/6/20.
//  Copyright © 2020 Austin Valleskey. All rights reserved.
//

import Foundation

@objc class CampCounts: BFJSONModel {
    @objc var icebreakers: NSNumber!
    @objc var posts: NSNumber!
    @objc var members: NSNumber!
    @objc var scoreIndex: NSNumber!
    @objc var live: NSNumber!
    @objc var postsNewForyou: NSNumber!
    @objc var posts24hr: NSNumber!
    
    @objc class override func keyMapper() -> JSONKeyMapper! {
        JSONKeyMapper.forSnakeCase()
    }
    
    override class func propertyIsOptional(_ propertyName: String!) -> Bool {
        true
    }
}
