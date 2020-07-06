//
//  StreamController.swift
//  Bonfire
//
//  Created by James Dale on 5/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation
import BFCore
import BFNetworking

final class StreamController: StreamControllerProtocol {
    
    private let api = APIClient.shared
    
    func getStream(completion: @escaping ([Post]) -> Void) {
        api.send(UserStreamRequest()) { (result) in
            switch result {
            case .success(let response):
                completion(response.data.map{ $0.attributes.posts }.reduce([], +))
            case .failure(let error):
                break
            }
        }
    }
}
