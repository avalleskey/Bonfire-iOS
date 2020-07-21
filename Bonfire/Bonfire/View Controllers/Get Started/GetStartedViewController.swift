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

    private let legalText: UILabel = {
        let label = UILabel()
        label.text =
            "By continuing, you agree to Bonfire’s Terms of Use and confirm that you have read Bonfire’s Privacy Policy."
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular).rounded()
        label.textColor = Constants.Color.secondary
        return label
    }()

    private let signInBtn: UIButton = {
        let btn = BFBouncyButton()
        btn.setTitle("Sign In", for: .normal)
        btn.setTitleColor(Constants.Color.primary, for: .normal)
        btn.backgroundColor = Constants.Color.primary.withAlphaComponent(0.06)
        btn.layer.cornerRadius = 14
        btn.addTarget(self, action: #selector(signInTapped), for: .touchUpInside)
        if let titleLabel = btn.titleLabel {
            titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold).rounded()
        }
        return btn
    }()

    private let continueWithAppleBtn: UIButton = {
        let btn = BFBouncyButton()
        btn.setTitle(" Continue with Apple", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .black
        btn.layer.cornerRadius = 14
        if let titleLabel = btn.titleLabel {
            titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold).rounded()
        }
        return btn
    }()

    private let signUpBtn: UIButton = {
        let btn = BFBouncyButton()
        btn.setTitle("Sign Up", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = Constants.Color.brand
        btn.layer.cornerRadius = 14
        if let titleLabel = btn.titleLabel {
            titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold).rounded()
        }
        return btn
    }()

    private let heroAlignmentView: UIView = {
        return UIView()
    }()

    private let heroStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        return stackView
    }()

    private let logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "GetStartedLogo")
        imageView.contentMode = .center
        imageView.backgroundColor = Constants.Color.pillBackground
        imageView.layer.shadowColor = UIColor.black.cgColor
        imageView.layer.shadowOpacity = 0.12
        imageView.layer.shadowOffset = .init(width: 0, height: 2)
        imageView.layer.cornerRadius = 22
        imageView.layer.shadowRadius = 3
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let primaryLabel: UILabel = {
        let label = UILabel()
        label.text = "Find your people"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 24, weight: .heavy).rounded()
        return label
    }()

    private let secondaryLabel: UILabel = {
        let label = UILabel()
        label.text = "Join Camps, make new friends,\ngo viral in For You and more"
        label.numberOfLines = 2
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular).rounded()
        label.textColor = Constants.Color.secondary
        return label
    }()

    init() {
        super.init(nibName: nil, bundle: nil)

        view.backgroundColor = Constants.Color.systemBackground
        view.addSubview(legalText)
        view.addSubview(signInBtn)
        view.addSubview(continueWithAppleBtn)
        view.addSubview(signUpBtn)
        view.addSubview(heroStackView)
        view.addSubview(heroAlignmentView)

        heroStackView.addArrangedSubview(logoImageView)
        heroStackView.setCustomSpacing(16, after: logoImageView)
        heroStackView.addArrangedSubview(primaryLabel)
        heroStackView.setCustomSpacing(8, after: primaryLabel)
        heroStackView.addArrangedSubview(secondaryLabel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func signInTapped(sender: UIButton) {
        let signInForm = BFFormViewController(form: BFSignInForm())
        present(signInForm, animated: true)
    }

    override func updateViewConstraints() {
        super.updateViewConstraints()

        legalText.translatesAutoresizingMaskIntoConstraints = false
        signInBtn.translatesAutoresizingMaskIntoConstraints = false
        continueWithAppleBtn.translatesAutoresizingMaskIntoConstraints = false
        signUpBtn.translatesAutoresizingMaskIntoConstraints = false
        heroAlignmentView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        heroStackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            legalText.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                constant: -24),
            legalText.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                constant: 24),
            legalText.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                constant: -24),

            signInBtn.bottomAnchor.constraint(
                equalTo: legalText.topAnchor,
                constant: -40),
            signInBtn.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                constant: 24),
            signInBtn.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                constant: -24),
            signInBtn.heightAnchor.constraint(equalToConstant: 48),

            continueWithAppleBtn.bottomAnchor.constraint(
                equalTo: signInBtn.topAnchor,
                constant: -16),
            continueWithAppleBtn.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                constant: 24),
            continueWithAppleBtn.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                constant: -24),
            continueWithAppleBtn.heightAnchor.constraint(equalToConstant: 48),

            signUpBtn.bottomAnchor.constraint(
                equalTo: continueWithAppleBtn.topAnchor,
                constant: -16),
            signUpBtn.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                constant: 24),
            signUpBtn.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                constant: -24),
            signUpBtn.heightAnchor.constraint(equalToConstant: 48),

            heroAlignmentView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            heroAlignmentView.bottomAnchor.constraint(equalTo: signUpBtn.topAnchor),
            heroAlignmentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            heroAlignmentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            heroStackView.leadingAnchor.constraint(equalTo: heroAlignmentView.leadingAnchor, constant:24),
            heroStackView.trailingAnchor.constraint(equalTo: heroAlignmentView.trailingAnchor, constant:-24),
            heroStackView.centerYAnchor.constraint(equalTo: heroAlignmentView.centerYAnchor),
            
            logoImageView.widthAnchor.constraint(equalToConstant: 96),
            logoImageView.heightAnchor.constraint(equalToConstant: 96),
        ])
    }

}
