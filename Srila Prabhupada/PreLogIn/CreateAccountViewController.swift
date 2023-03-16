//
//  CreateAccountViewController.swift
//  SrilaPrabhupada
//
//  Created by IE06 on 19/08/22.
//

import UIKit

class CreateAccountViewController: UIViewController {

    @IBOutlet private var emailTextField: UITextField!
    @IBOutlet private var passwordTextField: UITextField!
    @IBOutlet private var rePasswordTextField: UITextField!
    @IBOutlet private var createButton: UIButton!
    @IBOutlet private var loadingIndicatorView: UIActivityIndicatorView!

    private let signupViewModel: SignupViewModel = FirebaseEmailSignupViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        emailTextField.addTarget(self, action: #selector(textFieldDidChanged(_:)), for: .editingChanged)
        passwordTextField.addTarget(self, action: #selector(textFieldDidChanged(_:)), for: .editingChanged)
        rePasswordTextField.addTarget(self, action: #selector(textFieldDidChanged(_:)), for: .editingChanged)
    }

    @IBAction func createAccountTapped(_ sender: UIButton) {

        let validationResult = signupViewModel.isValidCredentials()
        switch validationResult {
        case .valid:

            showLoading()
            view.endEditing(true)

            signupViewModel.signup(completion: { [self] result in
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
        case .invalidConfirmPassword(message: let message):
            Haptic.warning()
            self.showAlert(title: "Invalid Confirm Password", message: message)
        }
    }

    @IBAction private func cancelButtonPressed(_: UIBarButtonItem) {
        goBack()
    }

    private func goBack() {
        if self.navigationController?.viewControllers.first == self {
            self.dismiss(animated: true, completion: nil)
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }

    private func showLoading() {
        loadingIndicatorView.startAnimating()

        if #available(iOS 13.0, *) {
            isModalInPresentation = true
        }
        emailTextField.isEnabled = false
        passwordTextField.isEnabled = false
        rePasswordTextField.isEnabled = false

        createButton.isEnabled = false
        navigationItem.hidesBackButton = true
    }

    private func hideLoading() {
        loadingIndicatorView.stopAnimating()

        if #available(iOS 13.0, *) {
            isModalInPresentation = false
        }
        emailTextField.isEnabled = true
        passwordTextField.isEnabled = true
        rePasswordTextField.isEnabled = true

        createButton.isEnabled = true
        navigationItem.hidesBackButton = false
    }
}

extension CreateAccountViewController: UITextFieldDelegate {

    @objc func textFieldDidChanged(_ textField: UITextField) {
        if textField == emailTextField {
            signupViewModel.username = textField.text
        } else if textField == passwordTextField {
            signupViewModel.password = textField.text
        } else if textField == rePasswordTextField {
            signupViewModel.confirmPassword = textField.text
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
}
