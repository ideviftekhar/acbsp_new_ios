//
//  LoginViewModel.swift
//  Srila Prabhupada
//
//  Created by IE on 9/12/22.
//

import UIKit
import FirebaseCore
import GoogleSignIn
import FirebaseAuth

enum LoginValidationResult {
    case valid
    case invalidUsername(message: String)
    case invalidPassword(message: String)
}

protocol LoginViewModel: AnyObject {

    var username: String? { get set }
    var password: String? { get set }

    func isValidCredentials() -> LoginValidationResult

    func login(presentingController: UIViewController, completion: @escaping (Swift.Result<FirebaseAuth.User, Error>) -> Void)
}

class FirebaseEmailLoginViewModel: NSObject, LoginViewModel {

    var username: String?
    var password: String?

    func isValidCredentials() -> LoginValidationResult {
        guard let username = username, !username.isEmpty else {
            return .invalidUsername(message: "Email is blank.")
        }

        guard username.isValidEmail else {
            return .invalidUsername(message: "Email is invalid.")
        }

        guard let password = password, !password.isEmpty else {
            return .invalidPassword(message: "Password is blank.")
        }

        guard password.count >= 6 else {
            return .invalidPassword(message: "Password must contains at least 6 characters")
        }

        return .valid
    }

    func login(presentingController: UIViewController, completion: @escaping (Result<User, Error>) -> Void) {

        guard let username = username, let password = password else {
            let error = NSError(domain: "Login", code: 0, userInfo: [NSLocalizedDescriptionKey: "Email or Password is blank"])
            completion(.failure(error))
            return
        }

        Auth.auth().signIn(withEmail: username, password: password) { authResult, error in

            if let error = error {
                completion(.failure(error))
            } else if let authResult = authResult {
                completion(.success(authResult.user))
            } else {
                let error = NSError(domain: "Login", code: 0, userInfo: [NSLocalizedDescriptionKey: "Something went wrong"])
                completion(.failure(error))
            }
        }
    }
}

class FirebaseGoogleLoginViewModel: NSObject, LoginViewModel {

    var username: String?
    var password: String?

    func isValidCredentials() -> LoginValidationResult {
        return .valid
    }

    func login(presentingController: UIViewController, completion: @escaping (Result<User, Error>) -> Void) {

        guard let clientID = FirebaseApp.app()?.options.clientID else { return }

        let config = GIDConfiguration(clientID: clientID)

        GIDSignIn.sharedInstance.signIn(with: config, presenting: presentingController) { user, error in

            if let error = error {
                completion(.failure(error))
            } else if let authentication = user?.authentication,
                      let idToken = authentication.idToken {

                let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                               accessToken: authentication.accessToken)

                Auth.auth().signIn(with: credential) { authResult, error in

                    if let error = error {
                        completion(.failure(error))
                    } else if let authResult = authResult {
                        completion(.success(authResult.user))
                    } else {
                        let error = NSError(domain: "Login", code: 0, userInfo: [NSLocalizedDescriptionKey: "Something went wrong"])
                        completion(.failure(error))
                    }
                }
            } else {
                let error = NSError(domain: "Login", code: 0, userInfo: [NSLocalizedDescriptionKey: "Something went wrong"])
                completion(.failure(error))
            }
        }
    }
}
