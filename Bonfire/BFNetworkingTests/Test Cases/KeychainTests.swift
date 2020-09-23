//
//  KeychainTests.swift
//  BFNetworkingTests
//
//  Created by James Dale on 6/8/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import KeychainSwift
import XCTest

@testable import BFNetworking

extension UIColor: Keychainable {}

final class KeychainTests: XCTestCase {

    private static let keychain = KeychainSwift(keyPrefix: "unit_test_")

    @KeychainProperty(key:.accessToken,keychain:keychain)
    private var str: String?

    @KeychainProperty(key:.accessToken,keychain:keychain)
    private var data: Data?

    @KeychainProperty(key:.accessToken,keychain:keychain)
    private var bool: Bool?

    @KeychainProperty(key:.accessToken,keychain:keychain)
    private var unsupported: UIColor?

    func testString() throws {
        str = "test"
        XCTAssertEqual(str, "test")
        str = nil
        XCTAssertNil(str)
    }

    func testData() throws {
        data = Data(count: 8)
        XCTAssertEqual(data, Data(count: 8))
        data = nil
        XCTAssertNil(data)
    }

    func testBool() throws {
        bool = true
        XCTAssertEqual(bool, true)
        bool = false
        XCTAssertEqual(bool, false)
        bool = nil
        XCTAssertNil(bool)
    }

    func testUnsupported() throws {
        unsupported = UIColor.blue
        XCTAssertNil(unsupported)
    }

}
