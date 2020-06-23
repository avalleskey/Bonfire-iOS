//
//  APIRequest.swift
//  Bonfire
//
//  Created by James Dale on 20/6/20.
//  Copyright © 2020 James Dale. All rights reserved.
//

import Foundation

public protocol APIRequest {
    associatedtype Response: Decodable
    
    var resource: String { get }
    
    var body: Data? { get }

    var method: String { get }
    
    var authenticationType: AuthenticationType { get }
}
