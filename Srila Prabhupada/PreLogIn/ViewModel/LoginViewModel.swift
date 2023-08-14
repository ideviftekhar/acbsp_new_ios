//
//  LoginViewModel.swift
//  Srila Prabhupada
//
//  Created by IE on 9/12/22.
//

import UIKit
import FirebaseAuth
import AuthenticationServices
import CryptoKit

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

    func login(presentingController: UIViewController, completion: @escaping (Result<FirebaseAuth.User, Error>) -> Void) {

        guard let username = username, let password = password else {
            let error = NSError(domain: "Login", code: 0, userInfo: [NSLocalizedDescriptionKey: "Email or Password is blank"])
            completion(.failure(error))
            return
        }

        FirestoreManager.shared.signIn(username: username, password: password, completion: completion)
    }
}

class FirebaseGoogleLoginViewModel: NSObject, LoginViewModel {

    var username: String?
    var password: String?

    func isValidCredentials() -> LoginValidationResult {
        return .valid
    }

    func login(presentingController: UIViewController, completion: @escaping (Result<FirebaseAuth.User, Error>) -> Void) {

        FirestoreManager.shared.signInWithGoogle(presentingController: presentingController, completion: completion)
    }
}

class FirebaseAppleLoginViewModel: NSObject, LoginViewModel {

    var username: String?
    var password: String?

    private var currentNonce: String?
    private var completion: ((Result<FirebaseAuth.User, Error>) -> Void)?

    private var contextProvider: AuthorizationContextProvider?

    private class AuthorizationContextProvider: NSObject, ASAuthorizationControllerPresentationContextProviding {

        weak var contextController: UIViewController?

        static var keyWindow: UIWindow? {
            let keyWindow: UIWindow?
            keyWindow = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first(where: { $0.isKeyWindow })

            return keyWindow
        }

        init(controller: UIViewController) {
            self.contextController = controller
        }
        func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
            return contextController?.view.window ?? Self.keyWindow!
        }
    }

    func isValidCredentials() -> LoginValidationResult {
        return .valid
    }

    func login(presentingController: UIViewController, completion: @escaping (Result<FirebaseAuth.User, Error>) -> Void) {

        let nonce = randomNonceString()
        currentNonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.email]
        request.nonce = sha256(nonce)

        contextProvider = AuthorizationContextProvider(controller: presentingController)
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = contextProvider
        authorizationController.performRequests()

        self.completion = completion
    }

    // Adapted from https://auth0.com/docs/api-auth/tutorials/nonce#generate-a-cryptographically-random-nonce
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError(
                        "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
                    )
                }
                return random
            }

            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }

                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()

        return hashString
    }
}

extension FirebaseAppleLoginViewModel: ASAuthorizationControllerDelegate {

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {

        guard let completion = completion else {
            return
        }

        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let nonce = currentNonce, let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            let error = NSError(domain: "Login", code: 0, userInfo: [NSLocalizedDescriptionKey: "Something went wrong"])
            completion(.failure(error))
            return
        }

        // Initialize a Firebase credential.
        let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                  idToken: idTokenString,
                                                  rawNonce: nonce)
        FirestoreManager.shared.signIn(credential: credential, completion: completion)
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        guard let completion = completion else {
            return
        }
        completion(.failure(error))
    }
}
