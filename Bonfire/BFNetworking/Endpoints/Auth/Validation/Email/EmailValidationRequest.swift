//
//  EmailValidation.swift
//  BFNetworking
//
//  Created by James Dale on 13/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import BFCore
import Foundation

public struct EmailValidationRequest: APIRequest {

    public typealias Response = EmailValidationResponse

    public let resource = "accounts/validate/email"

    public let body: Data? = nil

    public let queryItems: [URLQueryItem]? = nil

    public let method = "GET"

    public let authenticationType: AuthenticationType = .appAuth

    public init() {}
}
