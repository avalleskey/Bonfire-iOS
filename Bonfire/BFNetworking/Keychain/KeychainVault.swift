//
//  KeychainVault.swift
//  BFNetworking
//
//  Created by James Dale on 11/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation
import KeychainSwift

public struct KeychainVault {

    public typealias Token = String

    static private let keychain = KeychainSwift()

    @KeychainProperty(key: .accessToken, keychain: keychain)
    public static var accessToken: Token?

    @KeychainProperty(key: .refreshToken, keychain: keychain)
    public static var refreshToken: Token?

}
