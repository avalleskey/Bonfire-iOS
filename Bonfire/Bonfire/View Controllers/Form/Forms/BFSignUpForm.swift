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
        .init(path: \.phoneEmailUsername,
              type: .text,
              instructionText: "Welcome to Bonfire!\nWhat's your phone or email?",
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
              instructionText: "Let's get you signed up!\nPlease set a password",
              placeholderText: "Password",
              onCompletion: {
                
              },
              validate: { input -> Bool? in
                
                return true
              }),
        .init(path: \.birthDate,
              type: .date,
              instructionText: "What's your birthday?",
              placeholderText: nil,
              onCompletion: {
                 
              },
              validate: { input -> Bool? in
                switch input {
                case .date(_):
                    return true
                default:
                    return false
                }
              }),
        .init(path: \.imageData,
              type: .image,
              instructionText: "Set a profile picture\n(optional)",
              placeholderText: nil,
              onCompletion: {
                
              },
              validate: { input -> Bool? in
                return true
              }),
        .init(path: \.color,
              type: .color,
              instructionText: "Last step, and it's a fun one!\nWhat's your favorite color?",
              placeholderText: nil,
              onCompletion: {
                
              },
              validate: { input -> Bool? in
                switch input {
                case .date(_):
                    return true
                default:
                    return false
                }
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
            case .failure(_):
                completion(false)
            }
        }
    }

}
