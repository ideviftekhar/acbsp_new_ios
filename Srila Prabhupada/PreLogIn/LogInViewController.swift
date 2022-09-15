//
//  LogInViewController.swift
//  SrilaPrabhupada
//
//  Created by IE06 on 19/08/22.
//

import UIKit
import GoogleSignIn

class LogInViewController: UIViewController {
    
    @IBOutlet weak var imageView : UIImageView!
    
    @IBOutlet weak var emailTextField : UITextField!
    @IBOutlet weak var passwordTextField : UITextField!

    @IBOutlet weak var signInButton : UIButton!
    @IBOutlet weak var forgotPasswordButton : UIButton!
    @IBOutlet weak var createAccountButton : UIButton!
    @IBOutlet weak var signWithGoogleButton : GIDSignInButton!
    @IBOutlet weak var loadingIndicatorView: UIActivityIndicatorView!

    private let emailLoginViewModel: LoginViewModel = FirebaseEmailLoginViewModel()
    private let googleLoginViewModel: LoginViewModel = FirebaseGoogleLoginViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()

        emailTextField.addTarget(self, action: #selector(textFieldDidChanged(_:)), for: .editingChanged)
        passwordTextField.addTarget(self, action: #selector(textFieldDidChanged(_:)), for: .editingChanged)
    }
    
    @IBAction func signInTapped(_ sender: UIButton){

        let validationResult = emailLoginViewModel.isValidCredentials()
        switch validationResult {
        case .valid:

            showLoading()
            view.endEditing(true)
            emailLoginViewModel.login(presentingController: self) { [self] result in
                self.hideLoading()

                switch result {
                case .success:
                    let tabBarController = UIStoryboard.main.instantiate(UITabBarController.self)
                    self.present(tabBarController, animated: true, completion: nil)
                case .failure(let error):
                    self.showAlert(title: "Error", message: error.localizedDescription)
                }
            }
        case .invalidUsername(let message):
            self.showAlert(title: "Invalid Email", message: message)
        case .invalidPassword(let message):
            self.showAlert(title: "Invalid Password", message: message)
        }
    }

    @IBAction func signWithGoogleTapped(_ sender: UIButton) {

        showLoading()
        view.endEditing(true)

        googleLoginViewModel.login(presentingController: self) { [self] result in
            self.hideLoading()

            switch result {
            case .success:
                let tabBarController = UIStoryboard.main.instantiate(UITabBarController.self)
                self.present(tabBarController, animated: true, completion: nil)
            case .failure(let error):
                self.showAlert(title: "Error", message: error.localizedDescription)
            }
        }
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
    }

    private func hideLoading() {
        loadingIndicatorView.stopAnimating()

        emailTextField.isEnabled = true
        passwordTextField.isEnabled = true

        signInButton.isEnabled = true
        forgotPasswordButton.isEnabled = true
        createAccountButton.isEnabled = true
        signWithGoogleButton.isEnabled = true
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


