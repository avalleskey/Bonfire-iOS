//
//  EmailValidationResponse.swift
//  BFNetworking
//
//  Created by James Dale on 13/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation

public struct EmailValidationResponse: Decodable {

    let data: EmailValidationData

    struct EmailValidationData: Decodable {
        let valid: Bool
        let occupied: Bool
    }

}
