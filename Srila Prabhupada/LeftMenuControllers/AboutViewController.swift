//
//  AboutViewController.swift
//  SrilaPrabhupada
//
//  Created by IE06 on 02/09/22.
//

import UIKit
import SafariServices

class AboutViewController: UIViewController {

    @IBOutlet private var aboutImageContentView: UIView!
    @IBOutlet private var aboutImageView: UIImageView!

    @IBOutlet private var aboutAttributedLabel: TappableLabel!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var aboutLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.configureTappableLabel()

        titleLabel.text = Constants.appName
        aboutLabel.text = Constants.aboutText

        let attributedText = getNSAttributedString(mainString: Constants.aboutAttributedText, tapableString: Constants.aboutAttributedLinkString)
        aboutAttributedLabel.attributedText = attributedText
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()
        addShadowToImageView()
    }

    private func addShadowToImageView() {
        aboutImageContentView.shadowColor = UIColor.black
        aboutImageContentView.shadowOffset = .zero
        aboutImageContentView.shadowRadius = 100
        aboutImageContentView.shadowOpacity = 0.5
        aboutImageContentView.clipsToBounds = false
        aboutImageContentView.layer.shadowPath = UIBezierPath(roundedRect: aboutImageContentView.bounds, cornerRadius: 20).cgPath
    }

    func configureTappableLabel() {

        aboutAttributedLabel.delegate = self
        let linkString: String = Constants.aboutAttributedLinkString
        aboutAttributedLabel.addLink(linkString)
    }
    @IBAction private func cancelButtonTapped(_ sender: UIButton) {
        self.dismiss(animated: true)
    }
    
    private func getNSAttributedString(mainString: String, tapableString: String) -> NSAttributedString {
        
        let range = (mainString as NSString).range(of: tapableString)
        
        let attributedStringColor = [
            NSAttributedString.Key.foregroundColor : UIColor.systemOrange,
            .font: UIFont(name: "AvenirNextCondensed-Regular", size: 17)]// as [NSAttributedString.Key : Any]
        
        let mutableAttributedString = NSMutableAttributedString(string: mainString, attributes: attributedStringColor as [NSAttributedString.Key : Any])

        let attributes: [NSAttributedString.Key : Any] = [.underlineStyle: NSUnderlineStyle.single.rawValue, .foregroundColor: UIColor.F96D00]
        
        mutableAttributedString.addAttributes(attributes, range: range)
        
        return mutableAttributedString
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
