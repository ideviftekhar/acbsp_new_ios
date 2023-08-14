//
//  SceneDelegate.swift
//  Srila Prabhupada
//
//  Created by IE06 on 19/08/22.
//

import UIKit
import FirebaseAuth
import FirebaseDynamicLinks

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var unprocessedLectureID: Int?
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {

        guard let windowScene = scene as? UIWindowScene else { return }

        if let user = Auth.auth().currentUser {
            DispatchQueue.global().async {
                user.getIDToken { token, error in
                    if let error = error as? NSError {
                        if error.code == AuthErrorCode.userNotFound.rawValue ||
                            error.code == AuthErrorCode.userTokenExpired.rawValue ||
                            error.code == AuthErrorCode.invalidAPIKey.rawValue ||
                            error.code == AuthErrorCode.appNotAuthorized.rawValue ||
                            error.code == AuthErrorCode.invalidUserToken.rawValue ||
                            error.code == AuthErrorCode.userDisabled.rawValue {
                            DispatchQueue.main.async { [self] in
                                DefaultLectureViewModel.defaultModel.clearCache()
                                let loginNavigationController = UIStoryboard.main.instantiate(UINavigationController.self, identifier: "LoginNavigationController")

                                window = UIWindow(windowScene: windowScene)
                                window?.rootViewController = loginNavigationController
                                window?.makeKeyAndVisible()
                            }
                        }
                    }
                }
            }

            let controller = UIStoryboard.main.instantiate(LoadingViewController.self)
            controller.forceLoading = false

            windowScene.sizeRestrictions?.minimumSize = CGSize(width: 667, height: 667)
            windowScene.sizeRestrictions?.maximumSize = CGSize(width: 1366, height: 1366)

//            windowScene.sizeRestrictions?.maximumSize = CGSize(width: 1440, height: 900)

            window = UIWindow(windowScene: windowScene)
            window?.rootViewController = controller
            window?.makeKeyAndVisible()

//#if targetEnvironment(simulator)
//            handleURL(url: URL(string: "https://bvks.page.link/oAQN")!)
//#else
            if let urlContext = connectionOptions.urlContexts.first {
                handleURL(url: urlContext.url)
            } else if let userActivity = connectionOptions.userActivities.first,
                        let url = userActivity.webpageURL {
                handleURL(url: url)
            }
//#endif
        }
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        guard let url = userActivity.webpageURL else {
               return
        }
        handleURL(url: url)
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {

        guard let urlContext = URLContexts.first else {
            return
        }

        handleURL(url: urlContext.url)
    }

    @discardableResult private func handleURL(url: URL) -> Bool {
        let handled = DynamicLinks.dynamicLinks().handleUniversalLink(url) { dynamicLink, error in
            if let dynamicLink = dynamicLink {
                self.handleDynamicLink(dynamicLink: dynamicLink)
            }
        }
        return handled
    }

    private func handleDynamicLink(dynamicLink: DynamicLink) {
        print(dynamicLink)
        if let url = dynamicLink.url {
            if let component: URLComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                if let queryItem = component.queryItems?.first(where: { $0.name == "lectureId" }),
                    let lectureIdString = queryItem.value, let lectureID = Int(lectureIdString) {
                    if let tabBarController = self.window?.rootViewController as? TabBarController,
                       tabBarController.showPlayer(lectureID: lectureID, shouldPlay: true) {
                    } else {
                        unprocessedLectureID = lectureID
                    }
                }
            }
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
        print(#function)
    }

    func sceneWillResignActive(_ scene: UIScene) {
        print(#function)
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        print(#function)
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        print(#function)
    }
}
