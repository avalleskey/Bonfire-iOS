//
//  NotificationController.swift
//  Bonfire
//
//  Created by Austin Valleskey on 24/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import BFCore
import BFNetworking
import Foundation

final class NotificationController: NotificationControllerProtocol {
    
    private let api = APIClient.shared
    
    func getNotifications(completion: @escaping ([UserActivity]) -> Void) {
        api.send(UserNotificationsRequest()) { (result) in
            switch result {
            case .success(let response):
                completion(response.data)
            case .failure(let error):
                break
            }
        }
    }
}
