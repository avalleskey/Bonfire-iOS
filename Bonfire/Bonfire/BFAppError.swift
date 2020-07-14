//
//  BFAppError.swift
//  Bonfire
//
//  Created by James Dale on 11/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation
import BFNetworking

enum BFAppError: Error {
    case unauthenticated
    
    static func from(error: Error) -> Self? {
        switch error {
        case APIError.unauthenticated:
            return .unauthenticated
        default:
            return nil
        }
    }
}
