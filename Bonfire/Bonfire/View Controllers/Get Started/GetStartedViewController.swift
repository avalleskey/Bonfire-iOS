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
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular).rounded()
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
    
    let heroAlignmentView: UIView = {
        return UIView()
    }()
    
    let heroStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        return stackView
    }()
    
    let primaryLabel: UILabel = {
        let label = UILabel()
        label.text = "Find your people"
        label.textAlignment = .center
        return label
    }()
    
    let secondaryLabel: UILabel = {
        let label = UILabel()
        label.text = "Join Camps, make new friends, go viral in For You and more"
        label.numberOfLines = 2
        label.textAlignment = .center
        return label
    }()
    
    init() {
        super.init(nibName: nil, bundle: nil)
        
        view.backgroundColor = .white
        view.addSubview(legalText)
        view.addSubview(signInBtn)
        view.addSubview(continueWithAppleBtn)
        view.addSubview(signUpBtn)
        view.addSubview(heroStackView)
        view.addSubview(heroAlignmentView)
        
        heroStackView.addArrangedSubview(primaryLabel)
        heroStackView.addArrangedSubview(secondaryLabel)
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
        heroAlignmentView.translatesAutoresizingMaskIntoConstraints = false
        heroStackView.translatesAutoresizingMaskIntoConstraints = false
        
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
            signUpBtn.heightAnchor.constraint(equalToConstant: 48),
            
            heroAlignmentView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            heroAlignmentView.bottomAnchor.constraint(equalTo: signUpBtn.topAnchor),
            heroAlignmentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            heroAlignmentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            heroStackView.leadingAnchor.constraint(equalTo: heroAlignmentView.leadingAnchor),
            heroStackView.trailingAnchor.constraint(equalTo: heroAlignmentView.trailingAnchor),
            heroStackView.centerYAnchor.constraint(equalTo: heroAlignmentView.centerYAnchor),
            
            
        ])
    }
    
    
}
