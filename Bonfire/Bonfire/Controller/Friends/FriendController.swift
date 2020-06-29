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

final class UserController: FriendControllerProtocol {
    func getFriends(completion: @escaping (Result<[User], Error>) -> Void) {
        let api = APIClient.shared
        api.send(UserFriendsRequest()) { (result) in
            switch result {
            case .success(let response):
                completion(.success(response.data))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
