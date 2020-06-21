//
//  CampController.swift
//  Bonfire
//
//  Created by James Dale on 22/6/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation
import BFCore
import BFNetworking

final class CampController: CampControllerProtocol {
    func getCamps(completion: @escaping ([Camp]) -> Void) {
        completion([.init(name: "Steve")])
    }
}
