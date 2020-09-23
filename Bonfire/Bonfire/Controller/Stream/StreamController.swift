//
//  StreamController.swift
//  Bonfire
//
//  Created by James Dale on 5/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import BFCore
import BFNetworking
import Foundation

final class StreamController: StreamControllerProtocol {

    private let api = APIClient.shared

    func getStream(completion: @escaping ([Post]) -> Void) {
        api.send(UserStreamRequest(type: .me)) { (result) in
            switch result {
            case .success(let response):
                completion(response.data.compactMap { $0.attributes.posts }.reduce([], +))
            case .failure(let error):
                print(error)
                break
            }
        }
    }

    func getStream(userId: String, completion: @escaping ([Post]) -> Void) {
        api.send(UserStreamRequest(type: .otherUser(userId))) { (result) in
            switch result {
            case .success(let response):
                completion(response.data.compactMap { $0.attributes.posts }.reduce([], +))
            case .failure(let error):
                print(error)
                break
            }
        }
    }
    
    func getStream(campId: String, completion: @escaping ([Post]) -> Void) {
        api.send(CampStreamRequest(campId: campId)) { (result) in
            switch result {
            case .success(let response):
                completion(response.data.compactMap { $0.attributes.posts }.reduce([], +))
            case .failure(let error):
                print(error)
                break
            }
        }
    }
}
