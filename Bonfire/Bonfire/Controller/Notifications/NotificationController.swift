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
    func getNotifications(completion: @escaping (Result<[UserActivity], Error>) -> Void) {
        let api = APIClient.shared
        api.send(UserNotificationsRequest()) { (result) in
            switch result {
            case .success(let response):
                completion(.success(response.data))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
