//
//  StreamControllerProtocol.swift
//  Bonfire
//
//  Created by James Dale on 5/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import BFCore
import Foundation

protocol StreamControllerProtocol {
    func getStream(completion: @escaping ([Post]) -> Void)
}
