//
//  SignupViewModel.swift
//  Srila Prabhupada
//
//  Created by IE on 9/12/22.
//

import UIKit
import FirebaseAuth

enum SignupValidationResult {
    case valid
    case invalidUsername(message: String)
    case invalidPassword(message: String)
    case invalidConfirmPassword(message: String)
}

protocol SignupViewModel: AnyObject {

    var username: String? { get set }
    var password: String? { get set }
    var confirmPassword: String? { get set }

    func isValidCredentials() -> SignupValidationResult

    func signup(completion: @escaping (Swift.Result<FirebaseAuth.User, Error>) -> Void)
}

class FirebaseEmailSignupViewModel: NSObject, SignupViewModel {

    var username: String?
    var password: String?
    var confirmPassword: String?

    func isValidCredentials() -> SignupValidationResult {
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

        guard let confirmPassword = confirmPassword, !confirmPassword.isEmpty else {
            return .invalidPassword(message: "Confirm Password is blank.")
        }

        guard confirmPassword == password else {
            return .invalidPassword(message: "Password and confirm password doesn't match.")
        }

        return .valid
    }

    func signup(completion: @escaping (Result<User, Error>) -> Void) {

        guard let username = username, let password = password else {
            let error = NSError(domain: "Signup", code: 0, userInfo: [NSLocalizedDescriptionKey: "Email or Password is blank"])
            completion(.failure(error))
            return
        }

        Auth.auth().createUser(withEmail: username, password: password) { authResult, error in

            if let error = error {
                completion(.failure(error))
            } else if let authResult = authResult {
                completion(.success(authResult.user))
            } else {
                let error = NSError(domain: "Signup", code: 0, userInfo: [NSLocalizedDescriptionKey: "Something went wrong"])
                completion(.failure(error))
            }
        }
    }
}
