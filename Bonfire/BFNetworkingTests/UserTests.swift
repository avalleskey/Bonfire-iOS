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

final class UserProfileTests: XCTestCase {
    
    private let client = APIClient()

    func testUserProfile() throws {
        let expectation = XCTestExpectation(description: "User profile loads")
        client.send(UserProfileRequest(type: .me)) { (result) in
            switch result {
            case .success(_):
                expectation.fulfill()
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
        
        wait(for: [expectation], timeout: 10)
    }
    
    func testOtherUserProfile() throws {
        let expectation = XCTestExpectation(description: "User profile loads")
        client.send(UserProfileRequest(type: .otherUser("-rbVMBo75ADawYXOGRA"))) { (result) in
            switch result {
            case .success(_):
                expectation.fulfill()
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
        
        wait(for: [expectation], timeout: 10)
    }

}

