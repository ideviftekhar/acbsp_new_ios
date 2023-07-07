//
//  ContactUsViewController.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 7/6/23.
//

import UIKit
import MessageUI
import DeviceKit
import SafariServices

class ContactUsViewController: UIViewController {

    @IBOutlet private var emailButton: UIButton!
    @IBOutlet private var phoneButton: UIButton!
    @IBOutlet private var contactUsButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        emailButton.setTitle(CommonConstants.contactEmail, for: .normal)
        phoneButton.setTitle(CommonConstants.contactPhone, for: .normal)
        contactUsButton.setTitle(CommonConstants.contactLink, for: .normal)
    }

    @IBAction private func cancelButtonTapped(_ sender: UIButton) {
        self.dismiss(animated: true)
    }

    @IBAction private func emailTapped(_ sender: UIButton) {

        guard MFMailComposeViewController.canSendMail() else {
            self.showAlert(title: "Email Not Configured", message: "You device is not configured to send email.")
            return
        }

        let mailComposeVC = MFMailComposeViewController()
        mailComposeVC.mailComposeDelegate = self
        mailComposeVC.setToRecipients([CommonConstants.contactEmail])
        mailComposeVC.setSubject("Contact Us - \(Constants.appName)")

        var body: String = "\n\n\n\n------------------------"
        if let infoDictionary = Bundle.main.infoDictionary,
           let version = infoDictionary["CFBundleShortVersionString"] as? String,
           let build = infoDictionary["CFBundleVersion"] as? String {
            body += "\n" + Constants.appName + " v\(version) (\(build))"
        }

        body += "\nDevice: \(Device.current) (\(UIDevice.current.systemName) \(UIDevice.current.systemVersion))"

        mailComposeVC.setMessageBody(body, isHTML: false)

        present(mailComposeVC, animated: true)
    }

    @IBAction private func phoneTapped(_ sender: UIButton) {

        self.showAlert(title: nil, message: nil, preferredStyle: .actionSheet, sourceView: sender, cancel: (title: "Cancel", handler: nil), buttons: [(title: "WhatsApp", handler: {

            let cleanPhone = CommonConstants.contactPhone.filter { $0.isNumber || $0 == "+" }
            guard let whatsAppLink = URL(string: "https://api.whatsapp.com/send?phone=\(cleanPhone)"), UIApplication.shared.canOpenURL(whatsAppLink) else {
                self.showAlert(title: "WhatsApp Not Configured", message: "You can't send a whatsapp message at this time.")
                return
            }
            UIApplication.shared.open(whatsAppLink, options: [:], completionHandler: nil)
        }), (title: "Call", handler: {
            guard let phoneCallURL = URL(string: "tel://\(CommonConstants.contactPhone)"), UIApplication.shared.canOpenURL(phoneCallURL) else {
                self.showAlert(title: "Call Not Configured", message: "You device is not configured to call.")
                return
            }
            UIApplication.shared.open(phoneCallURL, options: [:], completionHandler: nil)
        })])

    }

    @IBAction private func contactUsTapped(_ sender: UIButton) {

        if let donateWebsite = URL(string: CommonConstants.contactLink) {
            let config = SFSafariViewController.Configuration()
            config.entersReaderIfAvailable = true
            let safariController = SFSafariViewController(url: donateWebsite, configuration: config)
            safariController.popoverPresentationController?.sourceView = sender
            self.present(safariController, animated: true, completion: nil)
        }
    }
}


extension ContactUsViewController : MFMailComposeViewControllerDelegate {

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}
