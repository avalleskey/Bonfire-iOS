//
//  CampMedia.swift
//  Pulse
//
//  Created by James Dale on 16/6/20.
//  Copyright © 2020 Austin Valleskey. All rights reserved.
//

import Foundation

@objc class CampMedia: BFJSONModel {
    @objc var avatar: BFHostedVersions!
    @objc var cover: BFHostedVersions!
    
    @objc class override func keyMapper() -> JSONKeyMapper! {
        JSONKeyMapper.forSnakeCase()
    }
    
    required init(dictionary dict: [AnyHashable : Any]!) throws {
        super.init()
        if let avatarDict = dict["avatar"] as? [AnyHashable: Any] {
            self.avatar = try BFHostedVersions(dictionary: avatarDict)
        }
        
        if let coverDict = dict["cover"] as? [AnyHashable: Any] {
            self.cover = try BFHostedVersions(dictionary: coverDict)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    required init(data: Data!) throws {
        fatalError("init(data:) has not been implemented")
    }
}
