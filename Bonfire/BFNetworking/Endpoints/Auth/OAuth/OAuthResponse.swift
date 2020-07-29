//
//  OAuthResponse.swift
//  BFNetworking
//
//  Created by James Dale on 12/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation

public struct OAuthResponse: Decodable {

    public let data: OAuthResponseData

    public struct OAuthResponseData: Decodable {
        public let accessToken: KeychainVault.Token
        public let refreshToken: KeychainVault.Token
        public let expiresAt: String // TODO: Add date decoding support
        public let scope: String

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case refreshToken = "refresh_token"
            case expiresAt = "expires_at"
            case scope
        }
    }
}
