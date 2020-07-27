//
//  NotificationControllerProtocol.swift
//  Bonfire
//
//  Created by Austin Valleskey on 24/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import BFCore
import Foundation

protocol NotificationControllerProtocol {
    func getNotifications(completion: @escaping (Result<[UserActivity], Error>) -> Void)
}
