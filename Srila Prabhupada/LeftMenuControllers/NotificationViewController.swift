//
//  NotificationViewController.swift
//  Srila Prabhupada
//
//  Created by IE03 on 17/06/23.
//

import Foundation
import UIKit
import FirebaseMessaging

class NotificationViewController : UIViewController {

    @IBOutlet var languageSwitches:[UISwitch]!
    
    @IBOutlet weak var englishLabel: UILabel!
    @IBOutlet weak var hindiLabel: UILabel!
    @IBOutlet weak var bengaliLabel: UILabel!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureSwitches()
        
        self.title = "Notifications"
        
        self.activityIndicator.isHidden = true
    }
    
    private func configureSwitches() {
        DefaultLectureViewModel.defaultModel.getNotificationInfo(source: .default, completion: { result in
            switch result {
            case .success(let result):
                
                for switchLangType in self.languageSwitches {
                    if switchLangType.tag == 0, let englishValue = result.notification?.english {
                        switchLangType.isOn = englishValue
                    }
                    
                    if switchLangType.tag == 1, let hindiValue = result.notification?.hindi {
                        switchLangType.isOn = hindiValue
                    }
                    
                    if switchLangType.tag == 2, let bengaliValue = result.notification?.bengali {
                        switchLangType.isOn = bengaliValue
                    }
                }
                
            case .failure(let error):
                self.showAlert(error: error.localizedDescription as! Error)
            }
        })
    }

    @IBAction func toggleNotificationAction(_ sender: UIButton) {

        let arrayLanguageTopics = [Constants.topicEnglish, Constants.topicHindi, Constants.topicBengali]
        
        if let fcmToken = UserDefaults.standard.string(forKey: CommonConstants.keyFcmToken), !fcmToken.isEmpty {
            for switchLangType in self.languageSwitches {
                //ERROR only one case execute: if switchLangType.tag == sender.tag, switchLangType.isOn {
                
                if switchLangType.tag == sender.tag {
                    
                    var documentData :[String: Any] = [:]
                    
                    if switchLangType.isOn {
                                                
                        if sender.tag == 0 {
                            documentData = ["notification": [CommonConstants.notificationKeyEnglish: false]]
                        } else if sender.tag == 1 {
                            documentData = ["notification": [CommonConstants.notificationKeyHindi: false]]
                        } else {
                            documentData = ["notification": [CommonConstants.notificationKeyBengali: false]]
                        }
                    } else {
                                                                        
                        if sender.tag == 0 {
                            documentData = ["notification": [CommonConstants.notificationKeyEnglish: true]]
                        } else if sender.tag == 1 {
                            documentData = ["notification": [CommonConstants.notificationKeyHindi: true]]
                        } else {
                            documentData = ["notification": [CommonConstants.notificationKeyBengali: true]]
                        }
                    }
                    
                self.updateDataInDB(documentData: documentData,
                                    switchLangType: switchLangType,
                                    arrayLanguageTopics: arrayLanguageTopics)

                }
            }
        } else {
            let error = NSError(domain: "Firestore Database", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to chnage: FCM Token is not available"])
            self.showAlert(error: error)
        }
        
    }
    
    private func updateDataInDB(documentData: [String: Any],
                                switchLangType: UISwitch,
                                arrayLanguageTopics: [String]) {
        
        self.activityIndicator.isHidden = false
        self.view.isUserInteractionEnabled = false
        self.activityIndicator.startAnimating()
        DefaultLectureViewModel.defaultModel.updateNotification(documentData: documentData) { result in
            self.activityIndicator.stopAnimating()
            self.activityIndicator.isHidden = true
            self.view.isUserInteractionEnabled = true
            switch result {
            
            case .success(let success):
                if success {
                    
                    if switchLangType.isOn {
                        switchLangType.setOn(false, animated: true)
                        
                        Messaging.messaging().unsubscribe(fromTopic: arrayLanguageTopics[switchLangType.tag], completion: { _ in
                            print("Unsubscribed to: \(arrayLanguageTopics[switchLangType.tag])")
                        })
                    } else {
                        switchLangType.setOn(true, animated: true)
                        
                        DispatchQueue.main.async {
                            Messaging.messaging().subscribe(toTopic: arrayLanguageTopics[switchLangType.tag]) { _ in
                                print("Subscribed to: \(arrayLanguageTopics[switchLangType.tag])")
                            }
                        }
                    }
                    
                }
                
            case .failure(let error):
                self.showAlert(error: error)
            }
        }
    }
}

