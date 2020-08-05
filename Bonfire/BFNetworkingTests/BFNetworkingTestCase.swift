//
//  BFNetworkingTestCase.swift
//  BFNetworkingTests
//
//  Created by James Dale on 6/8/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import XCTest

@testable import BFNetworking

open class BFNetworkingTestCase: XCTestCase {
    
    func apiTest<R: APIRequest>(client: APIClient, request: R) {
        let expectation = XCTestExpectation(description: "\(R.self) loads")
        client.send(request) { (result) in
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
