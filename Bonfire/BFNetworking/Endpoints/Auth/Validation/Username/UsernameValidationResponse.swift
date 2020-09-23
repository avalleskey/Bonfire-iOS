//
//  UsernameValidationResponse.swift
//  BFNetworking
//
//  Created by James Dale on 12/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation

public struct UsernameValidationResponse: Decodable {

    let data: UsernameValidationData

    struct UsernameValidationData: Decodable {
        let valid: Bool
        let occupied: Bool
        let authMethods: [String]
        let suggestions: [String]

        enum CodingKeys: String, CodingKey {
            case valid
            case occupied
            case authMethods = "auth_methods"
            case suggestions
        }
    }
}
