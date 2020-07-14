//
//  OAuthResponse.swift
//  BFNetworking
//
//  Created by James Dale on 12/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation

public final class OAuthResponse: Decodable {
    
    let data: OAuthResponseData
    
    struct OAuthResponseData: Decodable {
        let accessToken: KeychainVault.Token
        let refreshToken: KeychainVault.Token
        let expiresAt: Date
        let scope: String
        
        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case refreshToken = "refresh_token"
            case expiresAt = "expires_at"
            case scope
        }
    }
}
