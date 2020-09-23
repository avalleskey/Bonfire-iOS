//
//  UserTests.swift
//  BFNetworkingTests
//
//  Created by James Dale on 6/8/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation
import XCTest

@testable import BFNetworking

final class UserProfileTests: BFNetworkingTestCase {

    private let client = APIClient()

    func testUserProfile() throws {
        apiTest(client: client, request: UserProfileRequest(type: .me))
    }

    func testOtherUserProfile() throws {
        apiTest(
            client: client,
            request: UserProfileRequest(type: .otherUser("-rbVMBo75ADawYXOGRA")))
    }

    func testNotifications() throws {
        apiTest(client: client, request: UserNotificationsRequest())
    }

    func testStream() throws {
        apiTest(client: client, request: UserStreamRequest(type: .me))
    }

    func testFriends() throws {
        apiTest(client: client, request: UserFriendsRequest())
    }

}
