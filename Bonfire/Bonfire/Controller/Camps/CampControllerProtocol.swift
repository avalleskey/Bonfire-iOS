//
//  CampControllerProtocol.swift
//  Bonfire
//
//  Created by James Dale on 22/6/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import BFCore
import Foundation

protocol CampControllerProtocol {
    func getCamp(campId: String, completion: @escaping (Camp) -> Void)
    func getCampMembers(campId: String, completion: @escaping ([User]) -> Void)
    
    func getCamps(completion: @escaping ([Camp]) -> Void)
}
