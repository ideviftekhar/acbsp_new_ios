//
//  ForgotPasswordViewModel.swift
//  Srila Prabhupada
//
//  Created by IE on 9/12/22.
//

import UIKit

enum ForgotPasswordValidationResult {
    case valid
    case invalidUsername(message: String)
}

protocol ForgotPasswordViewModel: AnyObject {

    var username: String? { get set }

    func isValidCredentials() -> ForgotPasswordValidationResult

    func passwordReset(completion: @escaping (Swift.Result<String, Error>) -> Void)
}

class FirebaseForgotPasswordViewModel: NSObject, ForgotPasswordViewModel {

    var username: String?

    func isValidCredentials() -> ForgotPasswordValidationResult {
        guard let username = username, !username.isEmpty else {
            return .invalidUsername(message: "Email is blank.")
        }

        guard username.isValidEmail else {
            return .invalidUsername(message: "Email is invalid.")
        }

        return .valid
    }

    func passwordReset(completion: @escaping (Result<String, Error>) -> Void) {

        guard let username = username else {
            let error = NSError(domain: "ForgotPassword", code: 0, userInfo: [NSLocalizedDescriptionKey: "Email is blank"])
            completion(.failure(error))
            return
        }

        FirestoreManager.shared.sendPasswordReset(username: username, completion: completion)
    }
}
