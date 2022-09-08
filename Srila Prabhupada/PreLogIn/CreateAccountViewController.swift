//
//  CreateAccountViewController.swift
//  SrilaPrabhupada
//
//  Created by IE06 on 19/08/22.
//

import UIKit

class CreateAccountViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func createAccountTapped(_ sender: UIButton){
        let tabBarController = self.storyboard?.instantiateViewController(withIdentifier: "UITabBarController") as! UITabBarController
        self.present(tabBarController, animated: true)
    }
}
