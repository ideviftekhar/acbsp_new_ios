//
//  LogInViewController.swift
//  SrilaPrabhupada
//
//  Created by IE06 on 19/08/22.
//

import UIKit
import AuthenticationServices

class LogInViewController: UIViewController {

    @IBOutlet private var imageView: UIImageView!

    @IBOutlet private var emailTextField: UITextField!
    @IBOutlet private var passwordTextField: UITextField!

    @IBOutlet private var signInButton: UIButton!
    @IBOutlet private var forgotPasswordButton: UIButton!
    @IBOutlet private var createAccountButton: UIButton!
    @IBOutlet private var signWithGoogleButton: UIControl!
    @IBOutlet private var loadingIndicatorView: UIActivityIndicatorView!

    @IBOutlet private var googleAppleSignInStackView: UIStackView!

    private var _signWithAppleButton: Any?
    @available(iOS 13.0, *)
    fileprivate var signWithAppleButton: ASAuthorizationAppleIDButton {
        if _signWithAppleButton == nil {
            _signWithAppleButton = ASAuthorizationAppleIDButton()
        }
        return _signWithAppleButton as! ASAuthorizationAppleIDButton
    }
    private let emailLoginViewModel: LoginViewModel = FirebaseEmailLoginViewModel()
    private let googleLoginViewModel: LoginViewModel = FirebaseGoogleLoginViewModel()

    private var _appleLoginViewModel: Any?
    @available(iOS 13.0, *)
    fileprivate var appleLoginViewModel: LoginViewModel {
        if _appleLoginViewModel == nil {
            _appleLoginViewModel = FirebaseAppleLoginViewModel()
        }
        return _appleLoginViewModel as! LoginViewModel
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 13.0, *) {
            googleAppleSignInStackView.addArrangedSubview(signWithAppleButton)
            signWithAppleButton.addTarget(self, action: #selector(signWithAppleTapped(_:)), for: .touchUpInside)
        }

        emailTextField.addTarget(self, action: #selector(textFieldDidChanged(_:)), for: .editingChanged)
        passwordTextField.addTarget(self, action: #selector(textFieldDidChanged(_:)), for: .editingChanged)
    }

    @IBAction func signInTapped(_ sender: UIButton) {

        let validationResult = emailLoginViewModel.isValidCredentials()
        switch validationResult {
        case .valid:

            showLoading()
            view.endEditing(true)
            emailLoginViewModel.login(presentingController: self, completion: { [self] result in
                self.hideLoading()

                switch result {
                case .success:

                    Haptic.success()

                    if let keyWindow = self.view.window {
                        UIView.transition(with: keyWindow, duration: 0.5, options: .transitionFlipFromRight, animations: {
                            let loadingController = UIStoryboard.main.instantiate(LoadingViewController.self)
                            keyWindow.rootViewController = loadingController
                        })
                    }

                case .failure(let error):
                    Haptic.error()
                    self.showAlert(error: error)
                }
            })
        case .invalidUsername(let message):
            Haptic.warning()
            self.showAlert(title: "Invalid Email", message: message)
        case .invalidPassword(let message):
            Haptic.warning()
            self.showAlert(title: "Invalid Password", message: message)
        }
    }

    @IBAction func signWithGoogleTapped(_ sender: UIButton) {

        showLoading()
        view.endEditing(true)

        googleLoginViewModel.login(presentingController: self, completion: { [self] result in
            self.hideLoading()

            switch result {
            case .success:

                Haptic.success()

                if let keyWindow = self.view.window {
                    UIView.transition(with: keyWindow, duration: 0.5, options: .transitionFlipFromRight, animations: {
                        let loadingController = UIStoryboard.main.instantiate(LoadingViewController.self)
                        keyWindow.rootViewController = loadingController
                    })
                }

            case .failure(let error):
                Haptic.error()
                self.showAlert(error: error)
            }
        })
    }

    @available(iOS 13.0, *)
    @objc func signWithAppleTapped(_ sender: UIButton) {

        showLoading()
        view.endEditing(true)

        appleLoginViewModel.login(presentingController: self, completion: { [self] result in
            self.hideLoading()

            switch result {
            case .success:

                Haptic.success()

                if let keyWindow = self.view.window {
                    UIView.transition(with: keyWindow, duration: 0.5, options: .transitionFlipFromRight, animations: {
                        let loadingController = UIStoryboard.main.instantiate(LoadingViewController.self)
                        keyWindow.rootViewController = loadingController
                    })
                }

            case .failure(let error):
                Haptic.error()
                self.showAlert(error: error)
            }
        })
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let forgotPasswordController = segue.destination as? ForgotPasswordViewController {
            forgotPasswordController.prefillEmail = emailTextField.text
        }
    }

    private func showLoading() {
        loadingIndicatorView.startAnimating()

        emailTextField.isEnabled = false
        passwordTextField.isEnabled = false

        signInButton.isEnabled = false
        forgotPasswordButton.isEnabled = false
        createAccountButton.isEnabled = false
        signWithGoogleButton.isEnabled = false
        if #available(iOS 13.0, *) {
            signWithAppleButton.isEnabled = false
        }
    }

    private func hideLoading() {
        loadingIndicatorView.stopAnimating()

        emailTextField.isEnabled = true
        passwordTextField.isEnabled = true

        signInButton.isEnabled = true
        forgotPasswordButton.isEnabled = true
        createAccountButton.isEnabled = true
        signWithGoogleButton.isEnabled = true
        if #available(iOS 13.0, *) {
            signWithAppleButton.isEnabled = true
        }
    }
}

extension LogInViewController: UITextFieldDelegate {

    @objc func textFieldDidChanged(_ textField: UITextField) {
        if textField == emailTextField {
            emailLoginViewModel.username = textField.text
        } else if textField == passwordTextField {
            emailLoginViewModel.password = textField.text
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
}
