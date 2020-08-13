//
//  ProfileController.swift
//  Bonfire
//
//  Created by James Dale on 13/8/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import BFCore
import BFNetworking
import Foundation

final class ProfileController: ProfileControllerProtocol {
    
    private let api = APIClient.shared
    
    
    func getUser(completion: @escaping (User) -> Void) {
        api.send(UserProfileRequest(type: .me)) { (result) in
            switch result {
            case .success(let response):
                completion(response.data)
            case .failure(let error):
                break
            }
        }
    }
    
    func getUser(user: String, completion: @escaping (User) -> Void) {
        api.send(UserProfileRequest(type: .otherUser(user))) { (result) in
            switch result {
            case .success(let response):
                completion(response.data)
            case .failure(let error):
                break
            }
        }
    }
    
}
