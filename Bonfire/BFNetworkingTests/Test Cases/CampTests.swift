//
//  CampTests.swift
//  BFNetworkingTests
//
//  Created by James Dale on 6/8/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation
import XCTest

@testable import BFNetworking

final class CampTests: BFNetworkingTestCase {

    private let client = APIClient()

    func testMyCamps() throws {
        apiTest(client: client, request: MyCampsRequest())
    }

}
