//
//  ProfileControllerProtocol.swift
//  Bonfire
//
//  Created by James Dale on 13/8/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import BFCore
import Foundation

protocol ProfileControllerProtocol {
    func getUser(completion: @escaping (User) -> Void)
    func getUser(user: String, completion: @escaping (User) -> Void)
}

