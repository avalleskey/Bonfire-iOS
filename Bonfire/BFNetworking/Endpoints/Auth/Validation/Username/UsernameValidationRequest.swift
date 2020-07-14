//
//  UsernameValidation.swift
//  BFNetworking
//
//  Created by James Dale on 12/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation
import BFCore

final public class UsernameValidationRequest: APIRequest {
    public typealias Response = UsernameValidationResponse
    
    public let resource = "accounts/validate/username"
    
    public let body: Data? = nil
    
    public let queryItems: [URLQueryItem]? = nil

    public let method = "GET"
    
    public let authenticationType: AuthenticationType = .appAuth
    
    public init() {}
}
