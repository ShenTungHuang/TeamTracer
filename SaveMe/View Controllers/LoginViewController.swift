//
//  LoginViewController.swift
//  SaveMe
//
//  Created by STH on 2017/7/10.
//  Copyright © 2017年 STH. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseAuthUI
import FirebaseDatabase

typealias FIRUser = FirebaseAuth.User

class LoginViewController: UIViewController {
    
    // for button controler
    @IBOutlet weak var registerButton: UIButton!
    // to keep check status
    var checkAgreement: Bool = false
    var buttonColor: UIColor?
    // for generate new button
    lazy var agreementButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
//        button.setTitle("Agreement", for: .normal)
        button.setImage(#imageLiteral(resourceName: "AgreementButton"), for: .normal)
        button.setTitleColor(UIColor.black, for: .normal)
        button.isUserInteractionEnabled = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        buttonColor = registerButton.backgroundColor
        agreement()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func loginButtonTapped(_ sender: UIButton) {
        guard let authUI = FUIAuth.defaultAuthUI()
            else { return }
        
        authUI.delegate = self

        let authViewController = authUI.authViewController()
        present(authViewController, animated: true)
        
        print("login button tapped")
    }
    
    static func test() {
        print("called by AppDelegate")
    }
    
    func alertCheckBoxDidChangeView(checkBox: CheckboxButton){
        print("checkBox clicked = \(checkBox.on)")
        checkAgreement = checkBox.on
    }
    
    func setupAgreementButton() {
        self.view.addSubview(agreementButton)
        
        agreementButton.addTarget(self, action: #selector(agreement), for: .touchUpInside)
        agreementButton.heightAnchor.constraint(equalToConstant: 100).isActive = true
        agreementButton.widthAnchor.constraint(equalToConstant: 100).isActive = true
        agreementButton.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: 8).isActive = true
        agreementButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: 8).isActive = true
    }
    
    func agreement () {
        // Do any additional setup after loading the view.
        let alertController = UIAlertController(title: "", message: "", preferredStyle: .alert)
        
        // Change Title With Color and Font:
        let titleText  = "Terms of Service"
        var titleAttribute = NSMutableAttributedString()
        titleAttribute = NSMutableAttributedString(string: titleText as String, attributes: [NSFontAttributeName: UIFont(name: "HelveticaNeue-Light", size: 20.0)!])
        titleAttribute.addAttribute(NSForegroundColorAttributeName, value: UIColor.red, range: NSRange(location:0,length:titleText.characters.count))
        alertController.setValue(titleAttribute, forKey: "attributedTitle")
        // Change Message With Color and Font
        let messageText  = "\n1. If your are in danger, please make sure call 911 at first.\n\n2. Please make sure use this APP with internet service\n\n3. It's not a save APP, it just notice your friends to track your dynamic location.\n\n"
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = NSTextAlignment.left
        var messageAttribute = NSMutableAttributedString()
        messageAttribute = NSMutableAttributedString(string: messageText as String, attributes: [NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName: UIFont(name: "HelveticaNeue-Light", size: 16.0)!])
        messageAttribute.addAttribute(NSForegroundColorAttributeName, value: UIColor.black, range: NSRange(location:0,length:messageText.characters.count))
        messageAttribute.addAttribute(NSForegroundColorAttributeName, value: UIColor.red, range: NSRange(location:49,length:3))
        alertController.setValue(messageAttribute, forKey: "attributedMessage")
        
        if let alertContentView = alertController.view.subviews[0].subviews.last?.subviews.first?.subviews.first?.subviews[0] {
            let fridayLabel = UILabel(frame: CGRect(x: 10, y: 245, width: 100.0, height: 18.0))
            fridayLabel.font = UIFont.boldSystemFont(ofSize: 12.0)
            fridayLabel.textAlignment = .center
            fridayLabel.text = "I agree to the terms of agreement."
            fridayLabel.sizeToFit()
            fridayLabel.textColor = .black
            
            // Adding a check box
            let checkboxRect = CGRect(x: fridayLabel.frame.maxX + 10.0, y: fridayLabel.frame.minY, width: 18, height: 18)
            let checkbox = CheckboxButton(frame: checkboxRect, on: false)
            checkbox.borderStyle = 2
            checkbox.checkLineWidth = 3.0
            checkbox.cornerRadius = 3.0
            checkbox.checkColor = .white
            checkbox.containerFillsOnToggleOn = true
            checkbox.center = CGPoint(x: checkbox.center.x, y: fridayLabel.center.y)
            checkbox.addTarget(self, action: #selector(LoginViewController.alertCheckBoxDidChangeView(checkBox:)), for: .valueChanged)
            
            alertContentView.addSubview(fridayLabel)
            alertContentView.addSubview(checkbox)
        }
        
        let disagreeAction = UIAlertAction(title: "Disagree", style: UIAlertActionStyle.default) { (action) in
            print("disagree button tapped")
            self.registerButton.isEnabled = false
            self.registerButton.backgroundColor = UIColor.gray
            self.setupAgreementButton()
        }
        let accepyAction = UIAlertAction(title: "Accept", style: UIAlertActionStyle.default) { (action) in
            print("accept button tapped")
            if ( self.checkAgreement == true ) {
                print("accept OK")
                self.registerButton.isEnabled = true
                self.registerButton.backgroundColor = self.buttonColor
                self.agreementButton.isHidden = true
            } else  {
                print("not check")
                self.present(alertController, animated: true)
            }
        }
        alertController.addAction(disagreeAction)
        alertController.addAction(accepyAction)
        
        present(alertController, animated: true)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension LoginViewController: FUIAuthDelegate {

    func authUI(_ authUI: FUIAuth, didSignInWith user: FIRUser?, error: Error?) {
        if let error = error {
            assertionFailure("Error signing in: \(error.localizedDescription)")
            return
        }
        
        // check that the FIRUser returned from authentication is not nil by unwrapping it. We guard this statement, because we cannot proceed further if the user is nil
        guard let user = user
            else { return }
        
        
        UserService.show(forUID: user.uid) { (user) in
            if let user = user {
                // handle existing user
                User.setCurrent(user, writeToUserDefaults: true)
                
                print("Welcom back \(user.username)")
                
                let initialViewController = UIStoryboard.initialViewController(for: .main)
                self.view.window?.rootViewController = initialViewController
                self.view.window?.makeKeyAndVisible()
            } else {
                // handle new user
                self.performSegue(withIdentifier: Constants.Segue.toCreateUsername, sender: self)
            }
        }
    }
}
