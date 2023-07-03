//
//  CopyrightViewController.swift
//  SrilaPrabhupada
//
//  Created by IE06 on 02/09/22.
//

import UIKit

class CopyrightViewController: UIViewController {

    @IBOutlet private var copyrightLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        copyrightLabel.text = CommonConstants.copyrightText
    }
    @IBAction private func cancelButtonTapped(_ sender: UIButton) {
        self.dismiss(animated: true)
    }
}
