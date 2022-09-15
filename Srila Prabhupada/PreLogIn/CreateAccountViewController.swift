//
//  CreateAccountViewController.swift
//  SrilaPrabhupada
//
//  Created by IE06 on 19/08/22.
//

import UIKit

class CreateAccountViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var rePasswordTextField: UITextField!
    @IBOutlet weak var createButton: UIButton!
    @IBOutlet weak var loadingIndicatorView: UIActivityIndicatorView!

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

            signupViewModel.signup(completion:{ [self] result in
                self.hideLoading()

                switch result {
                case .success:
                    let tabBarController = UIStoryboard.main.instantiate(UITabBarController.self)
                    self.present(tabBarController, animated: true, completion: nil)
                case .failure(let error):
                    self.showAlert(title: "Error", message: error.localizedDescription)
                }
            })
        case .invalidUsername(let message):
            self.showAlert(title: "Invalid Email", message: message)
        case .invalidPassword(let message):
            self.showAlert(title: "Invalid Password", message: message)
        case .invalidConfirmPassword(message: let message):
            self.showAlert(title: "Invalid Confirm Password", message: message)
        }
    }

    private func showLoading() {
        loadingIndicatorView.startAnimating()

        emailTextField.isEnabled = false
        passwordTextField.isEnabled = false
        rePasswordTextField.isEnabled = false

        createButton.isEnabled = false
        navigationItem.hidesBackButton = true
    }

    private func hideLoading() {
        loadingIndicatorView.stopAnimating()

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


