//
//  AppDelegate.swift
//  Srila Prabhupada
//
//  Created by IE06 on 19/08/22.
//

import UIKit
import GoogleSignIn
import IQKeyboardManagerSwift
import FirebaseAuth
import FirebaseCore
import FirebaseMessaging
import FirebaseDynamicLinks
import SKActivityIndicatorView

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    static let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        IQKeyboardManager.shared.enable = true
        SKActivityIndicator.spinnerStyle(.spinningFadeCircle)

        FirebaseOptions.defaultOptions()?.deepLinkURLScheme = Constants.iOSBundleIdentifier

        if let filePath = Bundle.main.path(forResource: Environment.current.googleServiceFileName, ofType: "plist"),
           let fileopts = FirebaseOptions(contentsOfFile: filePath) {
            FirebaseApp.configure(options: fileopts)
        }

        // This is just to instantiate background session
        BackgroundSession.shared.performFetchWithCompletionHandler {}
        
        // Setting permission to send notification
        UNUserNotificationCenter.current().delegate = self

        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
          options: authOptions,
          completionHandler: { _, _ in }
        )

        application.registerForRemoteNotifications()
        
        Messaging.messaging().delegate = self

        if let userActivityDictionary = launchOptions?[.userActivityDictionary] as? [AnyHashable : Any],
            let userActivity = userActivityDictionary[UIApplication.LaunchOptionsKey.userActivityType] as? NSUserActivity, let webPageUrl = userActivity.webpageURL {

            print(webPageUrl)
            DynamicLinks.dynamicLinks().handleUniversalLink(webPageUrl) { (dynamicLink, error) in
                if let dynamicLink = dynamicLink {
                    self.handleDynamicLink(dynamicLink: dynamicLink)
                }
            }
        }

        return true
    }

    func currentKeyWindow() -> UIWindow? {
        let keyWindow: UIWindow? = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow })
        return keyWindow
    }

   // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }

    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {

        BackgroundSession.shared.performFetchWithCompletionHandler {
            completionHandler(.noData)
        }
    }


    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {

        guard Auth.auth().currentUser != nil, let url = userActivity.webpageURL else {
            return false
        }

        let handled = DynamicLinks.dynamicLinks().handleUniversalLink(url) { dynamicLink, error in
            if let dynamicLink = dynamicLink {
                self.handleDynamicLink(dynamicLink: dynamicLink)
            }
        }

        return handled
    }

    func application(_ application: UIApplication, handleOpen url: URL) -> Bool {
        return true
    }

    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) -> Bool {
        if GIDSignIn.sharedInstance.handle(url) {
            return true
        } else if self.application(application, open: url, sourceApplication: options[UIApplication.OpenURLOptionsKey
            .sourceApplication] as? String, annotation: "") {
            return true
        }

        return false
    }

    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        if let dynamicLink = DynamicLinks.dynamicLinks().dynamicLink(fromCustomSchemeURL: url) {
            handleDynamicLink(dynamicLink: dynamicLink)
            return true
        }
        return false
    }

    private func handleDynamicLink(dynamicLink: DynamicLink) {
        if let url = dynamicLink.url {
            if let component: URLComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                if let queryItem = component.queryItems?.first(where: { $0.name == "lectureId" }),
                    let lectureIdString = queryItem.value, let lectureID = Int(lectureIdString) {
                    if let tabBarController = self.currentKeyWindow()?.rootViewController as? TabBarController {
                        tabBarController.showPlayer(lectureID: lectureID, shouldPlay: true)
                    }
                }
            }
        }
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {

        Messaging.messaging().apnsToken = deviceToken
    }

    func application(_ application: UIApplication,
                     handleEventsForBackgroundURLSession identifier: String,
                     completionHandler: @escaping () -> Void) {
        BackgroundSession.shared.handleEventsForBackgroundURLSession(identifier: identifier, completionHandler: completionHandler)
    }
}

//To Receive messages in an Apple app
extension AppDelegate: UNUserNotificationCenterDelegate {
  // Receive displayed notifications for iOS 10 devices.
  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification) async
    -> UNNotificationPresentationOptions {
    let userInfo = notification.request.content.userInfo

    // With swizzling disabled you must let Messaging know about the message, for Analytics
    // Messaging.messaging().appDidReceiveMessage(userInfo)

    // ...

    // Print full message.
    print(userInfo)

    // Change this to your preferred presentation option
    return [[.alert, .sound]]
  }

  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse) async {
    let userInfo = response.notification.request.content.userInfo

    // ...

    // With swizzling disabled you must let Messaging know about the message, for Analytics
    // Messaging.messaging().appDidReceiveMessage(userInfo)

    // Print full message.
    print(userInfo)
  }
    
    //Handle silent push notifications
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any]) async
      -> UIBackgroundFetchResult {
      // If you are receiving a notification message while your app is in the background,
      // this callback will not be fired till the user taps on the notification launching the application.
      // TODO: Handle data of notification

      // With swizzling disabled you must let Messaging know about the message, for Analytics
      // Messaging.messaging().appDidReceiveMessage(userInfo)

      // Print message ID.
//      if let messageID = userInfo[gcmMessageIDKey] {
//        print("Message ID: \(messageID)")
//      }

      // Print full message.
      print(userInfo)

      return UIBackgroundFetchResult.newData
    }
}

extension AppDelegate: MessagingDelegate {
    //Monitor token refresh
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        
        //Save token to UserDefault
        let uds = UserDefaults.standard
        if (uds.string(forKey: CommonConstants.keyFcmToken) == nil) {
            uds.set(fcmToken, forKey: CommonConstants.keyFcmToken)
        }
        uds.synchronize()
        
        self.subscribeToTopics()
        
      print("Firebase registration token: \(String(describing: fcmToken))")

      let dataDict: [String: String] = ["token": fcmToken ?? ""]
      NotificationCenter.default.post(
        name: Notification.Name("FCMToken"),
        object: nil,
        userInfo: dataDict
      )
      // TODO: If necessary send token to application server.
      // Note: This callback is fired at each app startup and whenever a new token is generated.
    }
}

extension AppDelegate {
    private func subscribeToTopics() {
        
        DefaultLectureViewModel.defaultModel.getNotificationInfo(source: .default, completion: { result in
            switch result {

            case .success(let success):

                //To subscribe to a topic, call the subscription method from your application's main thread (FCM is not thread-safe).
                if let notification = success.notification, notification.english ?? false {
                    DispatchQueue.main.async {
                        Messaging.messaging().subscribe(toTopic: Constants.topicEnglish) { _ in
                          print("Subscribed to English")
                        }
                    }
                } else {
                    Messaging.messaging().unsubscribe(fromTopic: Constants.topicEnglish, completion: { _ in
                        print("Unsubscribed to English")
                    })
                }

                if let notification = success.notification, notification.hindi ?? false {
                    DispatchQueue.main.async {
                        Messaging.messaging().subscribe(toTopic: Constants.topicHindi) { _ in
                          print("Subscribed to Hindi")
                        }
                    }
                } else {
                    Messaging.messaging().unsubscribe(fromTopic: Constants.topicHindi, completion: { _ in
                        print("Unsubscribed to Hindi")
                    })
                }

                if let notification = success.notification, notification.bengali ?? false {
                    DispatchQueue.main.async {
                        Messaging.messaging().subscribe(toTopic: Constants.topicBengali) { _ in
                          print("Subscribed to Bengali")
                        }
                    }
                } else {
                    Messaging.messaging().unsubscribe(fromTopic: Constants.topicBengali, completion: { _ in
                        print("Unsubscribed to Bengali")
                    })
                }

            case .failure(let error):
                print(error.localizedDescription)
            }
        })
    }
}
