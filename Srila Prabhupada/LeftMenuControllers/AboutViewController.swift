//
//  AboutViewController.swift
//  SrilaPrabhupada
//
//  Created by IE06 on 02/09/22.
//

import UIKit
import SafariServices

class AboutViewController: UIViewController {

    @IBOutlet private var aboutImage: UIImageView!

    @IBOutlet private var aboutAttributedLabel: TappableLabel!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var aboutLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.configureTappableLabel()

        titleLabel.text = ""
    }

    func configureTappableLabel() {

        aboutAttributedLabel.delegate = self
        let linkString: String = "His Divine Grace A.C.Bhaktivedanta Swami Prabhupada"
        aboutAttributedLabel.addLink(linkString)
    }
}

extension AboutViewController: TappableLabelDelegate {
    func tappableLabel(_ label: TappableLabel, didTap string: String) {

        if let aboutWebSite = URL(string: Constants.aboutURLString) {
            let config = SFSafariViewController.Configuration()
            config.entersReaderIfAvailable = true
            let aboutWebPage = SFSafariViewController(url: aboutWebSite, configuration: config)
            aboutWebPage.popoverPresentationController?.sourceView = label

            present(aboutWebPage, animated: true)
        }
    }
}
