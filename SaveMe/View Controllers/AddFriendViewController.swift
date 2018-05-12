//
//  AddFriendViewController.swift
//  SaveMe
//
//  Created by STH on 2017/7/13.
//  Copyright © 2017年 STH. All rights reserved.
//

import UIKit
import FirebaseStorage
import FirebaseDatabase

class AddFriendViewController: UIViewController {

    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var dispnameTextField: UITextField!
    @IBOutlet weak var sendSwitch: UISwitch!
    
    var username: String = "123"
    var dispname: String = "123"
    var send_b: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        usernameLabel.text = username
        dispnameTextField.text = dispname
        sendSwitch.setOn(send_b, animated: send_b)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func setButtonTapped(_ sender: UIButton) {
//        print("set button tapped")
        
        let ref_send = Database.database().reference().child("users").child(User.current.uid).child("friends").child(username).child("send")
        ref_send.setValue(sendSwitch.isOn)
        let ref_dispname = Database.database().reference().child("users").child(User.current.uid).child("friends").child(username).child("dispname")
        ref_dispname.setValue(dispnameTextField.text!)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }

}
