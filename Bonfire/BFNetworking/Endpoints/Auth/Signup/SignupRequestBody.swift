//
//  SignupRequestBody.swift
//  BFNetworking
//
//  Created by James Dale on 13/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation

public struct SignupRequestBody: Encodable {
    let email: String
    let password: String
    let username: String
    let displayName: String
    let dateOfBirth: String
    
    enum CodingKeys: String, CodingKey {
        case email
        case password
        case username
        case displayName = "display_name"
        case dateOfBirth = "dob"
    }
}
