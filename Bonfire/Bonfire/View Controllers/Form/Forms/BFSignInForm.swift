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
        .init(
            path: \.phoneEmailUsername,
            type: .text,
            instructionText: "Hi again! 👋\nPlease sign in below",
            placeholderText: "Phone, email, username",
            onCompletion: {

            },
            validate: { (input, completion) in
                switch input {
                case .string(_):
                    completion(.success(true))
                default:
                    completion(.success(false))
                }
            }),
        .init(
            path: \.password,
            type: .password,
            instructionText: "Let's get you signed in!\nPlease enter your password",
            placeholderText: "Password",
            onCompletion: {

            },
            validate: { (input, completion) in
                completion(.success(true))
            }),
    ]

    func finalize(completion: @escaping (Bool) -> Void) {
        let requestBody = OAuthRequestBody(
            username: data.phoneEmailUsername?.stringValue,
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
            case .failure(_):
                completion(false)
            }
        }
    }

}
