//
//  Keychainable.swift
//  BFNetworking
//
//  Created by James Dale on 11/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation

public protocol Keychainable {}
extension String: Keychainable {}
extension Data: Keychainable {}
extension Bool: Keychainable {}
