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
        .init(path: \.phoneEmailUsername,
              type: .text,
              instructionText: "Hi again! 👋\nPlease sign in below",
              placeholderText: "Phone, email, username",
              onCompletion: {
                
              },
              validate: { input -> Bool? in
                switch input {
                case .string(_):
                    return true
                default:
                    return false
                }
              }),
        .init(path: \.password,
              type: .password,
              instructionText: "Let's get you signed in!\nPlease enter your password",
              placeholderText: "Password",
              onCompletion: {
                
              },
              validate: { input -> Bool? in
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
