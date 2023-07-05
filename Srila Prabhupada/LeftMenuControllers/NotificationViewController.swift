//
//  NotificationViewController.swift
//  Srila Prabhupada
//
//  Created by IE03 on 17/06/23.
//

import Foundation
import UIKit
import FirebaseMessaging

class NotificationViewController: UITableViewController {

    @IBOutlet private var englishSwitch: UISwitch!
    @IBOutlet private var hindiSwitch: UISwitch!
    @IBOutlet private var bengaliSwitch: UISwitch!

    @IBOutlet private var englishActivityIndicator: UIActivityIndicatorView!
    @IBOutlet private var hindiActivityIndicator: UIActivityIndicatorView!
    @IBOutlet private var bengaliActivityIndicator: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureSwitches()
    }
    
    private func configureSwitches() {
        englishSwitch.isHidden = true
        englishActivityIndicator.startAnimating()
        hindiSwitch.isHidden = true
        hindiActivityIndicator.startAnimating()
        bengaliSwitch.isHidden = true
        bengaliActivityIndicator.startAnimating()

        DefaultLectureViewModel.defaultModel.getNotificationInfo(source: .default, completion: { [self] result in

            englishSwitch.isHidden = false
            englishActivityIndicator.stopAnimating()
            hindiSwitch.isHidden = false
            hindiActivityIndicator.stopAnimating()
            bengaliSwitch.isHidden = false
            bengaliActivityIndicator.stopAnimating()

            switch result {
            case .success(let result):

                englishSwitch.isOn = result.notification?.english ?? false
                hindiSwitch.isOn = result.notification?.hindi ?? false
                bengaliSwitch.isOn = result.notification?.bengali ?? false

            case .failure(let error):
                self.showAlert(error: error.localizedDescription as! Error)
            }
        })
    }

    @IBAction func englishSwitchAction(_ sender: UISwitch) {

        guard let fcmToken = UserDefaults.standard.string(forKey: CommonConstants.keyFcmToken), !fcmToken.isEmpty else {
            let error = NSError(domain: "Firestore Database", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to chnage: FCM Token is not available"])
            self.showAlert(error: error)
            return
        }

        var documentData :[String: Any] = [:]
        documentData = ["notification": [CommonConstants.notificationKeyEnglish: sender.isOn]]

        englishSwitch.isHidden = true
        englishActivityIndicator.startAnimating()
        self.updateDataInDB(documentData: documentData, isOn: sender.isOn, languageTopic: Constants.topicEnglish) { [self] result in
            englishSwitch.isHidden = false
            englishActivityIndicator.stopAnimating()

            switch result {
            case .success(let success):
                sender.isOn = success
            case .failure(let failure):
                self.showAlert(error: failure)
                sender.isOn.toggle()
            }
        }
    }

    @IBAction func hindiSwitchAction(_ sender: UISwitch) {

        guard let fcmToken = UserDefaults.standard.string(forKey: CommonConstants.keyFcmToken), !fcmToken.isEmpty else {
            let error = NSError(domain: "Firestore Database", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to chnage: FCM Token is not available"])
            self.showAlert(error: error)
            return
        }

        var documentData :[String: Any] = [:]
        documentData = ["notification": [CommonConstants.notificationKeyHindi: sender.isOn]]

        hindiSwitch.isHidden = true
        hindiActivityIndicator.startAnimating()
        self.updateDataInDB(documentData: documentData, isOn: sender.isOn, languageTopic: Constants.topicHindi) { [self] result in
            hindiSwitch.isHidden = false
            hindiActivityIndicator.stopAnimating()

            switch result {
            case .success(let success):
                sender.isOn = success
            case .failure(let failure):
                self.showAlert(error: failure)
                sender.isOn.toggle()
            }
        }
    }

    @IBAction func bengaliSwitchAction(_ sender: UISwitch) {

        guard let fcmToken = UserDefaults.standard.string(forKey: CommonConstants.keyFcmToken), !fcmToken.isEmpty else {
            let error = NSError(domain: "Firestore Database", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to chnage: FCM Token is not available"])
            self.showAlert(error: error)
            return
        }

        var documentData :[String: Any] = [:]
        documentData = ["notification": [CommonConstants.notificationKeyBengali: sender.isOn]]

        bengaliSwitch.isHidden = true
        bengaliActivityIndicator.startAnimating()
        self.updateDataInDB(documentData: documentData, isOn: sender.isOn, languageTopic: Constants.topicBengali) { [self] result in
            bengaliSwitch.isHidden = false
            bengaliActivityIndicator.stopAnimating()

            switch result {
            case .success(let success):
                sender.isOn = success
            case .failure(let failure):
                self.showAlert(error: failure)
                sender.isOn.toggle()
            }
        }
    }

    private func updateDataInDB(documentData: [String: Any], isOn: Bool, languageTopic: String, completion: @escaping ((Result<Bool, Error>) -> Void)) {
        
        DefaultLectureViewModel.defaultModel.updateNotification(documentData: documentData) { result in
            switch result {
            case .success(let success):
                if isOn {
                    Messaging.messaging().subscribe(toTopic: languageTopic) { _ in
                        print("Subscribed to: \(languageTopic)")
                        DispatchQueue.main.async {
                            completion(.success(isOn))
                        }
                    }
                } else {
                    Messaging.messaging().unsubscribe(fromTopic: languageTopic, completion: { _ in
                        print("Unsubscribed to: \(languageTopic)")
                        DispatchQueue.main.async {
                            completion(.success(isOn))
                        }
                    })
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

