//
//  ChangePasswordViewController.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 13/04/23.
//

import UIKit

class ChangePasswordViewController: UIViewController {

    @IBOutlet private var currentPasswordTextField: UITextField!
    @IBOutlet private var newPasswordTextField: UITextField!
    @IBOutlet private var confirmNewPasswordTextField: UITextField!
    @IBOutlet private var changePasswordButton: UIButton!
    @IBOutlet private var loadingIndicatorView: UIActivityIndicatorView!
    
    private let emailLoginViewModel: LoginViewModel = FirebaseEmailLoginViewModel()
    private let signupViewModel: SignupViewModel = FirebaseEmailSignupViewModel()

    
    override func viewDidLoad() {
        super.viewDidLoad()

        emailLoginViewModel.username = FirestoreManager.shared.currentUserEmail
        signupViewModel.username = FirestoreManager.shared.currentUserEmail

        setupUI()
    }
    
    enum TextFieldName: CaseIterable {
        case currentPassword
        case newPassword
        case confirmPassword
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        if let alertController = self.presentedViewController as? UIAlertController {
            alertController.view.tintColor = UIColor.link
        }
    }

    @IBAction func changePasswordButtonTapped(_ sender: UIButton) {
        if validatePasswords(password: currentPasswordTextField.text, textFieldName: .currentPassword) {
            if validatePasswords(password: newPasswordTextField.text, textFieldName: .newPassword) {
                if validatePasswords(password: confirmNewPasswordTextField.text, textFieldName: .confirmPassword) {
                    let validationResult = emailLoginViewModel.isValidCredentials()
                    switch validationResult {
                    case .valid:
                        showLoading()
                        view.endEditing(true)
                        emailLoginViewModel.login(presentingController: self, completion: { [self] result in
                            self.hideLoading()
                            
                            switch result {
                            case .success:
                                updatePassword { error in
                                    if let error = error {
                                        Haptic.error()
                                        self.showAlert(title: "Error", message: "\(error.localizedDescription)")
                                    } else {
                                        Haptic.success()
                                        self.showAlert(title: "Success", message: "Your password is successfully updated.", cancel: (title: "OK", {
                                            self.navigationController?.popToRootViewController(animated: true)
                                        }))
                                    }
                                }
                                break
                            case .failure(let error):
                                self.showAlert(title: "Error", message: "\(error.localizedDescription)")
                                break
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
            }
        }
    }
    
    private func setupUI() {
        currentPasswordTextField.delegate = self
        newPasswordTextField.delegate = self
        confirmNewPasswordTextField.delegate = self
        
        currentPasswordTextField.addTarget(self, action: #selector(passwordTextFieldEditingChanged(_:)), for: .editingChanged)
        newPasswordTextField.addTarget(self, action: #selector(passwordTextFieldEditingChanged(_:)), for: .editingChanged)
        confirmNewPasswordTextField.addTarget(self, action: #selector(passwordTextFieldEditingChanged(_:)), for: .editingChanged)
    }
    
    private func updatePassword(completion: @escaping (Error?) -> Void) {
        guard let currentUser = FirestoreManager.shared.currentUser, let password = newPasswordTextField.text else {
            return
        }
        currentUser.updatePassword(to: password) { error in
            completion(error)
        }
    }
    
    private func showLoading() {
        loadingIndicatorView.startAnimating()

        currentPasswordTextField.isEnabled = true
        newPasswordTextField.isEnabled = true
        confirmNewPasswordTextField.isEnabled = true
        changePasswordButton.isEnabled = false
    }

    private func hideLoading() {
        loadingIndicatorView.stopAnimating()

        currentPasswordTextField.isEnabled = true
        newPasswordTextField.isEnabled = true
        confirmNewPasswordTextField.isEnabled = true
        changePasswordButton.isEnabled = true
    }
    
    func validatePasswords(password: String?, textFieldName: TextFieldName) -> Bool {
        
        switch textFieldName {
        case .currentPassword:
            guard let password = password, !password.isEmpty else {
                showAlert(title: "Invalid Password", message: "Current password is blank.")
                return false
            }
            return true
        case .newPassword:
            guard let password = password, !password.isEmpty else {
                showAlert(title: "Invalid Password", message: "New password field is blank.")
                return false
            }

            guard password.count >= 6 else {
                showAlert(title: "Invalid Password", message: "Password must contains at least 6 characters")
                return false
            }
            return true
        case .confirmPassword:
            guard let confirmPassword = password, !confirmPassword.isEmpty else {
                showAlert(title: "Invalid Password", message: "Confirm password field is blank.")
                return false
            }

            guard let newPasswordTextFieldText = newPasswordTextField.text, confirmPassword == newPasswordTextFieldText else {
                showAlert(title: "Invalid Password", message: "New password and confirm password doesn't match.")
                return false
            }
            return true
        }
    }
}

extension ChangePasswordViewController: UITextFieldDelegate {
    
    @objc private func passwordTextFieldEditingChanged(_ textField: UITextField) {
        switch textField {
        case currentPasswordTextField:
            emailLoginViewModel.password = textField.text
        case newPasswordTextField:
            signupViewModel.password = textField.text
        case confirmNewPasswordTextField:
            signupViewModel.confirmPassword = textField.text
        default:
            break
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        switch textField {
        case currentPasswordTextField:
            newPasswordTextField.becomeFirstResponder()
        case newPasswordTextField:
            confirmNewPasswordTextField.becomeFirstResponder()
        case confirmNewPasswordTextField:
            textField.resignFirstResponder()
        default:
            break
        }
        return true
    }
}
