//
//  UserProfileViewController.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 11/04/23.
//

import UIKit

class UserProfileViewController: UIViewController {

    @IBOutlet private var usernameLabel: UILabel!
    @IBOutlet private var userProfileImageView: UIImageView!
    @IBOutlet private var userEmailLabel: UILabel!
    @IBOutlet private var deleteAccountButton: UIButton!
    @IBOutlet private var changePasswordStackView: UIStackView!
    
    private var providerIDType: ProviderIDType?
    
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
    
    @IBAction func deleteAccountButtonTapped(_ sender: UIButton) {
        print("Move to deleteAccountViewController")
        if let deleteAccountController = UIStoryboard.sideMenu.instantiateViewController(withIdentifier: "DeleteAccountViewController") as? DeleteAccountViewController {
            deleteAccountController.providerIDType = self.providerIDType ?? .password
            self.navigationController?.pushViewController(deleteAccountController, animated: true)
        }
    }
    
    @IBAction func changePasswordButtonTapped(_ sender: UIButton) {
        print("Move to changePasswordViewController")
    }
    
    @IBAction func logOutButtonTapped(_ sender: UIButton) {
        
        self.showAlert(title: "Logout", message: "Are you sure you would like to Logout?", preferredStyle: .actionSheet, sourceView: sender, cancel: ("Cancel", nil), destructive: ("Logout", {
            FirestoreManager.shared.signOut(completion: { result in
                switch result {
                case .success:
                    
                    if let appTabBarController = self.appTabBarController,
                       !appTabBarController.playerViewController.isPaused {
                        appTabBarController.playerViewController.pause()
                        appTabBarController.playerViewController.currentLecture = nil
                        appTabBarController.playerViewController.playlistLectures = []
                    }
                    
                    if let keyWindow = self.view.window {
                        UIView.transition(with: keyWindow, duration: 0.5, options: .transitionFlipFromLeft, animations: {
                            let loginNavigationController = UIStoryboard.main.instantiate(UINavigationController.self, identifier: "LoginNavigationController")
                            keyWindow.rootViewController = loginNavigationController
                        })
                    }
                case .failure(let error):
                    Haptic.error()
                    self.showAlert(title: "Error!", message: error.localizedDescription)
                }
            })
        }))
    }

    var appTabBarController: TabBarController? {
        var controller: UIViewController = self
        
        while let presenting = controller.presentingViewController {
            controller = presenting
            if let controller = controller as? TabBarController {
                return controller
            }
        }
        return nil
    }
    

    private func setupUI() {
        changePasswordStackView.isHidden = true
        
        let firestoreManagerShared = FirestoreManager.shared
        if let currentUser = firestoreManagerShared.currentUser {
            for userInfo in currentUser.providerData {
                if userInfo.providerID == "password" {
                    print("User logged in with email/password")
                    changePasswordStackView.isHidden = false
                    providerIDType = .password
                    break
                } else if userInfo.providerID == "google.com" {
                    print("User logged in with google")
                    providerIDType = .google
                } else if userInfo.providerID == "apple.com" {
                    print("User logged in with Apple")
                    providerIDType = .apple
                }
            }
        }
        
        if let firestoreManagerSharedCurrentUser = firestoreManagerShared.currentUser {
            self.usernameLabel.text = firestoreManagerShared.currentUserDisplayName
            self.userEmailLabel.text = firestoreManagerShared.currentUserEmail
            
            var text = ""
            
            if let name = FirestoreManager.shared.currentUserDisplayName {
                text = name
            } else if let email = FirestoreManager.shared.currentUserEmail {
                text = email
            }
            
            let placeholderImage = userProfileImageView.placeholderImage(text: text)
            if let photoURL = firestoreManagerShared.currentUserPhotoURL {
                userProfileImageView.af.setImage(withURL: photoURL, placeholderImage: placeholderImage)
            } else {
                userProfileImageView.image = placeholderImage
            }
        } else {
            self.usernameLabel.text = "Username"
            self.userEmailLabel.text = "Email"
            userProfileImageView.image = userProfileImageView.placeholderImage(text: nil)
        }
        
        userProfileImageView.cornerRadius = userProfileImageView.frame.width / 2
        
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneButtonTapped))
        navigationItem.rightBarButtonItem = doneButton
    }
    @objc func doneButtonTapped() {
        self.navigationController?.dismiss(animated: true)
    }
    
    @IBAction func notificationAction(_ sender: UIButton) {
        
        if let notificationViewController = UIStoryboard.sideMenu.instantiateViewController(withIdentifier: "NotificationViewController") as? NotificationViewController {
            self.navigationController?.pushViewController(notificationViewController, animated: true)
        }
    }
}
