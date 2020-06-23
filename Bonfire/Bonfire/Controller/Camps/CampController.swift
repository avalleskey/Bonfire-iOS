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
    
    private let api = APIClient.shared
    
    func getCamps(completion: @escaping ([Camp]) -> Void) {
        api.send(TrendingCampsRequest()) { (result) in
            switch result {
            case .success(let camps):
                break
            case .failure(let error):
                break
            }
        }
    }
}
