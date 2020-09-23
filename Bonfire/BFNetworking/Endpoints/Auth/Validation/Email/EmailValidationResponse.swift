//
//  EmailValidationResponse.swift
//  BFNetworking
//
//  Created by James Dale on 13/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation

public struct EmailValidationResponse: Decodable {

    public let data: EmailValidationData

    public struct EmailValidationData: Decodable {
        public let valid: Bool
        public let occupied: Bool
    }

}
