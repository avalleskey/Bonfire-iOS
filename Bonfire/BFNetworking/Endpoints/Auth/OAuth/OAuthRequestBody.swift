//
//  OAuthRequestBody.swift
//  BFNetworking
//
//  Created by James Dale on 12/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation

public struct OAuthRequestBody: Encodable {
    
    let grantType = "password"

    public let username: String?
    public let password: String?

    public let phone: String?
    public let code: String?
    
    public init(username: String?, password: String?, phone: String?, code: String?) {
        self.username = username
        self.password = password
        self.phone = phone
        self.code = code
    }
    
    enum CodingKeys: String, CodingKey {
        case grantType = "grant_type"
        case username
        case password
        case phone
        case code
    }
}
