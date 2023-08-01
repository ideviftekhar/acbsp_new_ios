//
//  DeleteAccountViewController.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 11/04/23.
//

import UIKit
import AuthenticationServices

class DeleteAccountViewController: UIViewController {

    @IBOutlet private var userEmailLabel: UILabel!
    @IBOutlet private var deleteAccountButton: UIButton!
    @IBOutlet private var passwordTextField: UITextField!
    @IBOutlet private var loadingIndicatorView: UIActivityIndicatorView!
    
    var providerIDType: ProviderIDType = .password
    
    private let emailLoginViewModel: LoginViewModel = FirebaseEmailLoginViewModel()
    private let googleLoginViewModel: LoginViewModel = FirebaseGoogleLoginViewModel()

    fileprivate var appleLoginViewModel: LoginViewModel = FirebaseAppleLoginViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        if let alertController = self.presentedViewController as? UIAlertController {
            alertController.view.tintColor = UIColor.link
        }
    }
    
    private func setupUI() {
        
        passwordTextField.isHidden = true
        
        if providerIDType == .password {
            passwordTextField.isHidden = false
        }
        passwordTextField.addTarget(self, action: #selector(passwordTextFieldEditingChanged(_:)), for: .editingChanged)
        if let passwordTextFieldText = passwordTextField.text {
            if passwordTextField.isHidden {
                deleteAccountButton.isEnabled = true
            } else {
                deleteAccountButton.isEnabled = !passwordTextFieldText.isEmpty
            }
        }
        let firestoreManagerShared = FirestoreManager.shared
        if let firestoreManagerSharedCurrentUserEmail = firestoreManagerShared.currentUserEmail {
            self.userEmailLabel.text = firestoreManagerSharedCurrentUserEmail
            emailLoginViewModel.username = firestoreManagerSharedCurrentUserEmail
        } else {
            self.userEmailLabel.text = "Email"
        }
    }
    
    private func showLoading() {
        loadingIndicatorView.startAnimating()

        passwordTextField.isEnabled = false
        deleteAccountButton.isEnabled = false
    }

    private func hideLoading() {
        loadingIndicatorView.stopAnimating()

        passwordTextField.isEnabled = true
        deleteAccountButton.isEnabled = true
    }
}

extension DeleteAccountViewController: UITextFieldDelegate {
    @objc private func passwordTextFieldEditingChanged(_ textField: UITextField) {
        if let textFieldText = textField.text {
            emailLoginViewModel.password = textField.text
            deleteAccountButton.isEnabled = !passwordTextField.isHidden && !textFieldText.isEmpty
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension DeleteAccountViewController {
    
    @IBAction func deleteButtonTapped(_ sender: UIButton) {
        switch providerIDType {
        case .password:
            loginUserWithEmailPassword()
        case .google:
            loginUserWithGoogle()
        case .apple:
            loginUserWithApple()
        }
    }

    private func loginUserWithGoogle() {
        
        showLoading()
        googleLoginViewModel.login(presentingController: self, completion: { [self] result in
            self.hideLoading()
            
            switch result {
            case .success:
                deleteUserFiles()
                
            case .failure(let error):
                self.showAlert(error: error)
            }
        })
    }
    
    private func loginUserWithApple() {
        showLoading()
        appleLoginViewModel.login(presentingController: self, completion: { [self] result in
            self.hideLoading()
            
            switch result {
            case .success:
                deleteUserFiles()
                
            case .failure(let error):
                self.showAlert(error: error)
            }
        })
    }
    
    private func loginUserWithEmailPassword() {
        let validationResult = emailLoginViewModel.isValidCredentials()
        switch validationResult {
        case .valid:
            showLoading()
            view.endEditing(true)
            emailLoginViewModel.login(presentingController: self, completion: { [self] result in
                self.hideLoading()

                switch result {
                case .success:
                    deleteUserFiles()

                case .failure(let error):
                    self.showAlert(title: "Incorrect Password", message: error.localizedDescription)
                    Haptic.error()
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

extension DeleteAccountViewController {
    
    private func deleteUserFiles() {
        showAlert(title: "Delete Account", message: "Are you sure you want to delete account?", cancel: ("Cancel", nil), destructive: ("Delete", {
            self.deleteUserPrivatePlaylists()
        }))
    }
    
    private func deleteUserPrivatePlaylists() {
        showLoading()

        DefaultPlaylistViewModel.defaultModel.getPrivatePlaylist(searchText: nil, sortType: .default) { result in
            
            self.hideLoading()
            switch result {
            case .success(let success):
                for model in success {
                    DefaultPlaylistViewModel.defaultModel.delete(playlist: model) { _ in }
                }
                self.deleteUserPublicPlaylists()
            case .failure(let error):
                self.showAlert(error: error)
            }
        }
    }
    
    private func deleteUserPublicPlaylists() {
        
        let userEmail: String = FirestoreManager.shared.currentUserEmail ?? ""

        showLoading()

        DefaultPlaylistViewModel.defaultModel.getPublicPlaylist(searchText: nil, sortType: .default, userEmail: userEmail) { result in

            self.hideLoading()

            switch result {
            case .success(let success):
                for model in success {
                    DefaultPlaylistViewModel.defaultModel.delete(playlist: model) { _ in }
                }
                self.deleteUserAccount()
            case .failure(let error):
                self.showAlert(error: error)
                Haptic.error()
            }
        }
    }
    
    private func deleteUserAccount() {
        guard let user = FirestoreManager.shared.currentUser else {
            print("No user currently logged in")
            return
        }
        showLoading()

        user.delete { error in
            
            self.hideLoading()

            if let error = error {
                self.showAlert(error: error)
                Haptic.error()
            } else {
                Haptic.success()
                if let keyWindow = self.view.window {
                    UIView.transition(with: keyWindow, duration: 0.5, options: .transitionFlipFromLeft, animations: {
                        let loginNavigationController = UIStoryboard.main.instantiate(UINavigationController.self, identifier: "LoginNavigationController")
                        keyWindow.rootViewController = loginNavigationController
                    })
                }
            }
        }
    }
}
