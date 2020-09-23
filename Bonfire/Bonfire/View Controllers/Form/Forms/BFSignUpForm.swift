//
//  BFSignUpForm.swift
//  Bonfire
//
//  Created by James Dale on 21/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import BFNetworking
import Foundation

struct BFSignUpForm<FormData: BFSignUpData>: BFForm {
    typealias DataType = FormData
    let data: FormData = .init()

    let items: [BFFormItem<FormData>] = [
        .init(
            path: \.phoneEmailUsername,
            type: .text,
            instructionText: "Welcome to Bonfire!\nWhat's your phone or email?",
            placeholderText: "Phone, email, username",
            onCompletion: {

            },
            validate: { (input, completion) in
                switch input {
                case .string(let str):
                    completion(.success(str.replacingOccurrences(of: " ", with: "").count > 0))
                default:
                    return
                }
            }),
        .init(
            path: \.password,
            type: .password,
            instructionText: "Let's get you signed up!\nPlease set a password",
            placeholderText: "Password",
            onCompletion: {

            },
            validate: { (input, completion) in
                completion(.success(true))
            }),
        .init(
            path: \.birthDate,
            type: .date,
            instructionText: "When's your birthday?",
            placeholderText: nil,
            onCompletion: {

            },
            validate: { (input, completion) in
                switch input {
                case .date(_):
                    completion(.success(true))
                default:
                    completion(.success(false))
                }
            }),
        .init(
            path: \.imageData,
            type: .image,
            instructionText: "Set a profile picture\n(optional)",
            placeholderText: nil,
            onCompletion: {

            },
            validate: { (input, completion) in
                completion(.success(true))
            }),
        .init(
            path: \.color,
            type: .color,
            instructionText: "Last step, and it's a fun one!\nWhat's your favorite color?",
            placeholderText: nil,
            onCompletion: {

            },
            validate: { (input, completion) in
                switch input {
                case .date(_):
                    completion(.success(false))
                default:
                    completion(.success(false))
                }
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
