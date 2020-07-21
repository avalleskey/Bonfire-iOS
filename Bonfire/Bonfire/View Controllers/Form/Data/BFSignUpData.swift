//
//  BFSignUpData.swift
//  Bonfire
//
//  Created by James Dale on 21/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation

final class BFSignUpData: BFFormData {
    var phoneEmailUsername: BFFormItemValue?
    var password: BFFormItemValue?
    var birthDate: BFFormItemValue?
    var imageData: BFFormItemValue?
    var color: BFFormItemValue?

    init() {}
}
