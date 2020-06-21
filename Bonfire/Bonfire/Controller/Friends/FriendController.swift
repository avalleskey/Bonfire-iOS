//
//  FriendController.swift
//  Bonfire
//
//  Created by James Dale on 22/6/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation
import BFCore
import BFNetworking

final class FriendController: FriendControllerProtocol {
    func getFriends(completion: @escaping ([Result<User, Error>]) -> Void) {
        completion([])
    }
}
