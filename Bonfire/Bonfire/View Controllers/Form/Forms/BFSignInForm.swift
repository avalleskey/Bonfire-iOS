//
//  BFSignInForm.swift
//  Bonfire
//
//  Created by James Dale on 13/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation
import BFNetworking

struct BFSignInForm: BFForm {
    
    let items: [BFFormItem] = {
        let phoneUsername = BFFormItem(path: \BFSignInData.phoneEmailUsername,
                              type: .text) {
            
        } validate: {
            return true
        }
        
        let password = BFFormItem(path: \BFSignInData.password,
                                  type: .password) {
            APIClient.shared.send(EmailValidationRequest()) { (result) in
                
            }
        } validate: {
            return true
        }


        return [phoneUsername, password]
    }()
    
}
