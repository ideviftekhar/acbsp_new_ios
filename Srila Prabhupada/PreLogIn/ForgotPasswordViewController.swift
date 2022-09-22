//
//  ForgotPasswordViewController.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 9/8/22.
//

import UIKit

class ForgotPasswordViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var loadingIndicatorView: UIActivityIndicatorView!

    private let forgotPasswordViewModel: ForgotPasswordViewModel = FirebaseForgotPasswordViewModel()

    var prefillEmail: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        emailTextField.text = prefillEmail
        emailTextField.addTarget(self, action: #selector(textFieldDidChanged(_:)), for: .editingChanged)
    }

    @IBAction func submitAction(_ sender: Any) {

        let validationResult = forgotPasswordViewModel.isValidCredentials()
        switch validationResult {
        case .valid:

            showLoading()
            view.endEditing(true)

            forgotPasswordViewModel.signup(completion: { [self] result in
                self.hideLoading()

                switch result {
                case .success(let message):
                    self.showAlert(title: "Success", message: message, cancel: (title: "OK", {
                        self.navigationController?.popViewController(animated: true)
                    }))
                case .failure(let error):
                    self.showAlert(title: "Error", message: error.localizedDescription)
                }
            })
        case .invalidUsername(let message):
            self.showAlert(title: "Invalid Email", message: message)
        }
    }

    private func showLoading() {
        loadingIndicatorView.startAnimating()

        emailTextField.isEnabled = false

        submitButton.isEnabled = false
        navigationItem.hidesBackButton = true
    }

    private func hideLoading() {
        loadingIndicatorView.stopAnimating()

        emailTextField.isEnabled = true

        submitButton.isEnabled = true
        navigationItem.hidesBackButton = false
    }
}

extension ForgotPasswordViewController: UITextFieldDelegate {

    @objc func textFieldDidChanged(_ textField: UITextField) {
        if textField == emailTextField {
            forgotPasswordViewModel.username = textField.text
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
}
