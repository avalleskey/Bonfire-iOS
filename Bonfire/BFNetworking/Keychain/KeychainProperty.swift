//
//  KeychainProperty.swift
//  BFNetworking
//
//  Created by James Dale on 11/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation
import KeychainSwift

@propertyWrapper
public struct KeychainProperty<Value: Keychainable> {

    public let key: KeychainKey

    public var keychain = KeychainSwift()

    public var wrappedValue: Value? {
        get {
            switch Value.self {
            case is String.Type:
                return keychain.get(key.rawValue) as? Value
            case is Bool.Type:
                return keychain.getBool(key.rawValue) as? Value
            case is Data.Type:
                return keychain.getData(key.rawValue) as? Value
            default:
                return nil
            }
        }
        set {
            if let str = newValue as? String {
                keychain.set(str, forKey: key.rawValue)
            } else if let bool = newValue as? Bool {
                keychain.set(bool, forKey: key.rawValue)
            } else if let data = newValue as? Data {
                keychain.set(data, forKey: key.rawValue)
            }
        }
    }

}
