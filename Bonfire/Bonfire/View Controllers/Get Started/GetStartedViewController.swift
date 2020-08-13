//
//  GetStartedViewController.swift
//  Bonfire
//
//  Created by James Dale on 09/7/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import AuthenticationServices
import Foundation
import SafariServices
import UIKit

final class GetStartedViewController: UIViewController {

    private let legalButton: UIButton = {
        let button = UIButton(type: .custom)
        button.addTarget(self, action: #selector(legalOptions), for: .touchUpInside)

        let string =
            "By continuing, you agree to Bonfire’s Terms of Use and confirm that you have read Bonfire’s Privacy Policy."
            as NSString
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .regular).rounded(),
            .foregroundColor: Constants.Color.secondary,
        ]
        let mutableAttributedString = NSMutableAttributedString(
            string: string as String, attributes: attributes)

        let highlightedAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: Constants.Color.primary,
        ]
        mutableAttributedString.addAttributes(
            highlightedAttributes, range: string.range(of: "Terms of Use") as NSRange)
        mutableAttributedString.addAttributes(
            highlightedAttributes, range: string.range(of: "Privacy Policy") as NSRange)

        button.setAttributedTitle(mutableAttributedString, for: .normal)
        if let title = button.titleLabel {
            title.lineBreakMode = .byWordWrapping
            title.textAlignment = .center
        }

        return button
    }()

    private let signInBtn: UIButton = {
        let btn = BFBouncyButton()
        btn.setTitle("Sign In", for: .normal)
        btn.setTitleColor(Constants.Color.primary, for: .normal)
        btn.backgroundColor = Constants.Color.primary.withAlphaComponent(0.06)
        btn.layer.cornerRadius = 14
        btn.addTarget(self, action: #selector(signInTapped), for: .touchUpInside)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold).rounded()
        return btn
    }()

    private let continueWithAppleBtn: UIButton = {
        let btn = BFBouncyButton()
        btn.setTitle(" Continue with Apple", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .black
        btn.layer.cornerRadius = 14
        if #available(iOS 13.0, *) {
            btn.addTarget(
                self, action: #selector(continueWithAppleTapped(sender:)), for: .touchUpInside)
        } else {
            btn.isEnabled = false
        }
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold).rounded()
        return btn
    }()

    private let signUpBtn: UIButton = {
        let btn = BFBouncyButton()
        btn.setTitle("Sign Up", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = Constants.Color.brand
        btn.layer.cornerRadius = 14
        btn.addTarget(self, action: #selector(signUpTapped), for: .touchUpInside)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold).rounded()
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
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(dismissViewController))

        view.backgroundColor = Constants.Color.systemBackground
        view.addSubview(legalButton)
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
    
    @objc func dismissViewController() {
        dismiss(animated: true, completion: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func signUpTapped(sender: UIButton) {
        let signUpForm = BFFormViewController(form: BFSignUpForm())
        navigationController?.pushViewController(signUpForm, animated: true)
    }

    @objc private func signInTapped(sender: UIButton) {
        let signInForm = BFFormViewController(form: BFSignInForm())
        navigationController?.pushViewController(signInForm, animated: true)
    }

    @available(iOS 13.0, *)
    @objc private func continueWithAppleTapped(sender: UIButton) {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let authController = ASAuthorizationController(authorizationRequests: [request])
        authController.presentationContextProvider = self
        authController.performRequests()
    }

    override func updateViewConstraints() {
        super.updateViewConstraints()

        legalButton.translatesAutoresizingMaskIntoConstraints = false
        signInBtn.translatesAutoresizingMaskIntoConstraints = false
        continueWithAppleBtn.translatesAutoresizingMaskIntoConstraints = false
        signUpBtn.translatesAutoresizingMaskIntoConstraints = false
        heroAlignmentView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        heroStackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            legalButton.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                constant: -24),
            legalButton.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                constant: 24),
            legalButton.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                constant: -24),

            signInBtn.bottomAnchor.constraint(
                equalTo: legalButton.topAnchor,
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

            heroStackView.leadingAnchor.constraint(
                equalTo: heroAlignmentView.leadingAnchor, constant: 24),
            heroStackView.trailingAnchor.constraint(
                equalTo: heroAlignmentView.trailingAnchor, constant: -24),
            heroStackView.centerYAnchor.constraint(equalTo: heroAlignmentView.centerYAnchor),

            logoImageView.widthAnchor.constraint(equalToConstant: 96),
            logoImageView.heightAnchor.constraint(equalToConstant: 96),
        ])
    }

    @objc func legalOptions() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.view.tintColor = Constants.Color.primary

        let termsOfUseAction = UIAlertAction(
            title: "Terms of Use", style: .default,
            handler: { (action) in
                guard let url = URL(string: "https://bonfire.camp/legal/terms") else { return }
                let svc = SFSafariViewController(url: url)
                svc.modalPresentationStyle = .popover
                self.present(svc, animated: true, completion: nil)
            })
        alert.addAction(termsOfUseAction)

        let privacyPolicyAction = UIAlertAction(
            title: "Privacy Policy", style: .default,
            handler: { (action) in
                guard let url = URL(string: "https://bonfire.camp/legal/privacy") else { return }
                let svc = SFSafariViewController(url: url)
                svc.modalPresentationStyle = .popover
                self.present(svc, animated: true, completion: nil)
            })
        alert.addAction(privacyPolicyAction)

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

@available(iOS 13.0, *)
extension GetStartedViewController: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        self.view.window!
    }
}
