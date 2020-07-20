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
    let data: FormData = .init()

    let items: [BFFormItem<FormData>] = [
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
    
    func finalize(completion: @escaping (Bool) -> ()) {
        let requestBody = OAuthRequestBody(username: data.phoneEmailUsername?.stringValue,
                                           password: data.password?.stringValue,
                                           phone: nil,
                                           code: nil)
        APIClient.shared.send(OAuthRequest(body: requestBody)) { (result) in
            switch result {
            case .success(let response):
                DispatchQueue.main.async {
                    KeychainVault.accessToken = response.data.accessToken
                    KeychainVault.refreshToken = response.data.refreshToken
                    completion(true)
                }
            case .failure(let error):
                completion(false)
            }
        }
    }

}
