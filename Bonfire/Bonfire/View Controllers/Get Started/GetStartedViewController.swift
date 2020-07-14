//
//  GetStartedViewController.swift
//  Bonfire
//
//  Created by James Dale on 09/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation
import UIKit

final class GetStartedViewController: UIViewController {
    
    let legalText: UILabel = {
        let label = UILabel()
        label.text = "By continuing, you agree to Bonfire’s Terms of Use and confirm that you have read Bonfire’s Privacy Policy."
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        label.font = label.font.rounded()
        return label
    }()
    
    let signInBtn: UIButton = {
        let btn = UIButton()
        btn.setTitle("Sign In", for: .normal)
        btn.setTitleColor(.black, for: .normal)
        btn.backgroundColor = .lightGray
        btn.layer.cornerRadius = 14
        return btn
    }()
    
    let continueWithAppleBtn: UIButton = {
        let btn = UIButton()
        btn.setTitle("Continue with Apple", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .black
        btn.layer.cornerRadius = 14
        return btn
    }()
    
    let signUpBtn: UIButton = {
        let btn = UIButton()
        btn.setTitle("Sign Up", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = Constants.Color.bfOrange
        btn.layer.cornerRadius = 14
        return btn
    }()
    
    init() {
        super.init(nibName: nil, bundle: nil)
        
        view.backgroundColor = .white
        view.addSubview(legalText)
        view.addSubview(signInBtn)
        view.addSubview(continueWithAppleBtn)
        view.addSubview(signUpBtn)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        
        legalText.translatesAutoresizingMaskIntoConstraints = false
        signInBtn.translatesAutoresizingMaskIntoConstraints = false
        continueWithAppleBtn.translatesAutoresizingMaskIntoConstraints = false
        signUpBtn.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            legalText.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                                              constant: -24),
            legalText.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                                               constant: 48),
            legalText.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                                                constant: -48),
            
            signInBtn.bottomAnchor.constraint(equalTo: legalText.topAnchor,
                                              constant: -32),
            signInBtn.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                                               constant: 24),
            signInBtn.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                                                constant: -24),
            signInBtn.heightAnchor.constraint(equalToConstant: 48),
            
            continueWithAppleBtn.bottomAnchor.constraint(equalTo: signInBtn.topAnchor,
                                                         constant: -16),
            continueWithAppleBtn.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                                                          constant: 24),
            continueWithAppleBtn.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                                                           constant: -24),
            continueWithAppleBtn.heightAnchor.constraint(equalToConstant: 48),
            
            signUpBtn.bottomAnchor.constraint(equalTo: continueWithAppleBtn.topAnchor,
                                              constant: -16),
            signUpBtn.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                                               constant: 24),
            signUpBtn.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                                                constant: -24),
            signUpBtn.heightAnchor.constraint(equalToConstant: 48)
            
            
        ])
    }
    
    
}
