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
    
    let username: String?
    let password: String?
    
    let phone: String?
    let code: String?
}
