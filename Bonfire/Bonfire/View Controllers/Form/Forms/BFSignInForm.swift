//
//  BFSignInForm.swift
//  Bonfire
//
//  Created by James Dale on 13/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import BFNetworking
import Foundation

struct BFSignInForm<FormData: BFSignInData>: BFForm {

    typealias DataType = FormData
    var data: FormData = .init()

    var items: [BFFormItem<FormData>] = [
        .init(path: \.phoneEmailUsername, type: .text,
            onCompletion: {

            },
            validate: { () -> Bool? in
                return true
            }),
        .init(path: \.password, type: .password,
            onCompletion: {

            },
            validate: { () -> Bool? in
                return true
            }),
    ]


    //    let items: [BFFormItem<FormData>] = {
    ////        let phoneUsername = BFFormItem(path: \BFSignInData.phoneEmailUsername,
    ////                              type: .text) {
    ////
    ////        } validate: {
    ////            return true
    ////        }
    ////
    ////        let password = BFFormItem(path: \BFSignInData.password,
    ////                                  type: .password) {
    ////            APIClient.shared.send(EmailValidationRequest()) { (result) in
    ////
    ////            }
    ////        } validate: {
    ////            return true
    ////        }
    ////
    ////
    ////        return [phoneUsername, password]
    //        return []
    //    }()

}
