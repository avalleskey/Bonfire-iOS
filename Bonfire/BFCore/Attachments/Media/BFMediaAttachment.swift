//
//  BFMediaAttachment.swift
//  BFCore
//
//  Created by James Dale on 30/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation

public struct BFMediaAttachment: Codable {

    public let id: String?

    public let type: BFResourceType
    
    public let attributes: Attributes

    public struct Attributes: Codable {
        public let hostedVersions: BFMediaType

        enum CodingKeys: String, CodingKey {
            case hostedVersions = "hosted_versions"
        }
    }

}
