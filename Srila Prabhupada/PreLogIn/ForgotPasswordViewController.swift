//
//  ForgotPasswordViewController.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 9/8/22.
//

import UIKit

class ForgotPasswordViewController: UIViewController {

    @IBOutlet private var emailTextField: UITextField!
    @IBOutlet private var submitButton: UIButton!
    @IBOutlet private var loadingIndicatorView: UIActivityIndicatorView!
    
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

            forgotPasswordViewModel.passwordReset(completion: { [self] result in
                self.hideLoading()

                switch result {
                case .success(let message):
                    Haptic.success()
                    self.showAlert(title: "Success", message: message, cancel: (title: "OK", {
                        self.dismiss(animated: true)
                    }))
                case .failure(let error):
                    Haptic.error()
                    self.showAlert(error: error)
                }
            })
        case .invalidUsername(let message):
            Haptic.warning()
            self.showAlert(title: "Invalid Email", message: message)
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

        submitButton.isEnabled = false
        navigationItem.hidesBackButton = true
    }

    private func hideLoading() {
        loadingIndicatorView.stopAnimating()

        if #available(iOS 13.0, *) {
            isModalInPresentation = false
        }
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
