//
//  CampController.swift
//  Bonfire
//
//  Created by James Dale on 22/6/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import BFCore
import BFNetworking
import Foundation

final class CampController: CampControllerProtocol {

    private let api = APIClient.shared
    
    func getCamp(campId: String, completion: @escaping (Camp) -> Void) {
        api.send(CampRequest(campId: campId)) { (result) in
            switch result {
            case .success(let response):
                completion(response.data)
            case .failure(let error):
                print(error)
                break
            }
        }
    }
    
    func getCampMembers(campId: String, completion: @escaping ([User]) -> Void) {
        api.send(CampMembersRequest(campId: campId)) { (result) in
            switch result {
            case .success(let response):
                completion(response.data)
            case .failure(let error):
                print(error)
                break
            }
        }
    }
    
    func getCamps(completion: @escaping ([Camp]) -> Void) {
        api.send(MyCampsRequest()) { (result) in
            switch result {
            case .success(let response):
                completion(response.data)
            case .failure(let error):
                print(error)
                break
            }
        }
    }
}
