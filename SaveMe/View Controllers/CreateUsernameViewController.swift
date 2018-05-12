//
//  CreateUsernameViewController.swift
//  SaveMe
//
//  Created by STH on 2017/7/10.
//  Copyright © 2017年 STH. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class CreateUsernameViewController: UIViewController {

    @IBOutlet weak var userNameTextField: UITextField!
    @IBOutlet weak var nextButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        nextButton.layer.cornerRadius = 6
    }
    
    @IBAction func nextButtonTapped(_ sender: UIButton) {
//        print("next button tapped")
        guard let firUser = Auth.auth().currentUser,
            let username = userNameTextField.text,
            !username.isEmpty else { return }
        
        UserService.create(firUser, username: username) { (user) in
            if let user = user {
                User.setCurrent(user, writeToUserDefaults: true)
            } else {
                // handle error
                return
            }
            
            let initialViewController = UIStoryboard.initialViewController(for: .main)
            self.view.window?.rootViewController = initialViewController
            self.view.window?.makeKeyAndVisible()
        }

    }

}
