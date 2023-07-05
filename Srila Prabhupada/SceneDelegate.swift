//
//  SceneDelegate.swift
//  Srila Prabhupada
//
//  Created by IE06 on 19/08/22.
//

import UIKit
import FirebaseAuth

@available(iOS 13.0, *)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {

        guard let windowScene = scene as? UIWindowScene else { return }

        // hack.iftekhar@gmail.com // uid: 6JquqE4j4yPBrtrAhvRyIvCMxN02
        if let user = Auth.auth().currentUser {
            DispatchQueue.global().async {
                user.getIDToken { _, error in
                    if error != nil {

                        DispatchQueue.main.async { [self] in
                            let loginNavigationController = UIStoryboard.main.instantiate(UINavigationController.self, identifier: "LoginNavigationController")

                            window = UIWindow(windowScene: windowScene)
                            window?.rootViewController = loginNavigationController
                            window?.makeKeyAndVisible()
                        }
                    }
                }
            }

            let controller = UIStoryboard.main.instantiate(LoadingViewController.self)
            controller.forceLoading = false

            windowScene.sizeRestrictions?.minimumSize = CGSize(width: 375, height: 667)
            windowScene.sizeRestrictions?.maximumSize = CGSize(width: 1024, height: 1366)

            window = UIWindow(windowScene: windowScene)
            window?.rootViewController = controller
            window?.makeKeyAndVisible()
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        if let scene = scene as? UIWindowScene {
            for window in scene.windows {
                if let tabBarController = window.rootViewController as? TabBarController {
                    tabBarController.playerViewController.updateLectureProgress()
                }
            }
        }
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
    }

    func sceneWillResignActive(_ scene: UIScene) {
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
    }
}
