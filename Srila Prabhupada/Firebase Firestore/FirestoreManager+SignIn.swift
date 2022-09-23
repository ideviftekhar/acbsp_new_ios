//
//  FirestoreManager+SignIn.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 9/23/22.
//

import Foundation
import GoogleSignIn
import FirebaseAuth
import FirebaseCore

extension FirestoreManager {

    func signUp(username: String, password: String, completion: @escaping (Result<FirebaseAuth.User, Error>) -> Void) {
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

    func sendPasswordReset(username: String, completion: @escaping (Result<String, Error>) -> Void) {

        Auth.auth().sendPasswordReset(withEmail: username) { error in

            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success("We have successully sent reset password link to your email."))
            }
        }
    }

    func signOut(completion: @escaping (Result<Bool, Error>) -> Void) {
        do {
            try FirebaseAuth.Auth.auth().signOut()
            completion(.success(true))
        } catch let error {
            completion(.failure(error))
        }
    }

    func signIn(username: String, password: String, completion: @escaping (Result<FirebaseAuth.User, Error>) -> Void) {
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

    func signInWithGoogle(presentingController: UIViewController, completion: @escaping (Result<FirebaseAuth.User, Error>) -> Void) {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            let error = NSError(domain: "Login", code: 0, userInfo: [NSLocalizedDescriptionKey: "Something went wrong"])
            completion(.failure(error))
            return
        }

        let config = GIDConfiguration(clientID: clientID)

        GIDSignIn.sharedInstance.signIn(with: config, presenting: presentingController) { [self] user, error in

            if let error = error {
                completion(.failure(error))
            } else if let authentication = user?.authentication,
                      let idToken = authentication.idToken {

                let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                               accessToken: authentication.accessToken)

                signIn(credential: credential, completion: completion)
            } else {
                let error = NSError(domain: "Login", code: 0, userInfo: [NSLocalizedDescriptionKey: "Something went wrong"])
                completion(.failure(error))
            }
        }
    }

    func signIn(credential: AuthCredential, completion: @escaping (Result<FirebaseAuth.User, Error>) -> Void) {
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
    }
}
