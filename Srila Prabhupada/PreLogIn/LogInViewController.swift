//
//  LogInViewController.swift
//  SrilaPrabhupada
//
//  Created by IE06 on 19/08/22.
//

import UIKit

class LogInViewController: UIViewController {
    
    @IBOutlet weak var imageView : UIImageView!
    
    @IBOutlet weak var emailTextField : UITextField!
    @IBOutlet weak var passwordTextField : UITextField!

    @IBOutlet weak var signInButton : UIButton!
    @IBOutlet weak var forgotPasswordButton : UIButton!
    @IBOutlet weak var createAccountButton : UIButton!
    @IBOutlet weak var signWithGoogleButton : UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func signInTapped(_ sender: UIButton){
        let tabBarController = self.storyboard?.instantiateViewController(withIdentifier: "UITabBarController") as! UITabBarController
        self.present(tabBarController, animated: true)
    }

    @IBAction func signWithGoogleTapped(_ sender: UIButton){
        let tabBarController = self.storyboard?.instantiateViewController(withIdentifier: "UITabBarController") as! UITabBarController
        self.present(tabBarController, animated: true)
    }
}

