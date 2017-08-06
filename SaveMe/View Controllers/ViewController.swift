//
//  ViewController.swift
//  SaveMe
//
//  Created by STH on 2017/7/10.
//  Copyright © 2017年 STH. All rights reserved.
//

import UIKit
import Firebase
import UserNotifications
import FirebaseInstanceID
import FirebaseMessaging


class ViewController: UIViewController {

    @IBOutlet weak var clockLabel: UILabel!
    @IBOutlet weak var firstLabel: UILabel!
    @IBOutlet weak var secondLabel: UILabel!
    
    @IBOutlet weak var redButton: UIButton!
    @IBOutlet weak var friendListButton: UIButton!
    
    var viewTimer:Timer!
    var myTimeCoumnt: Int = 24
    
    var didTapNotification: Bool = false
    
    // Singleton?
    static var sharedInstance: ViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        redButton.setImage(#imageLiteral(resourceName: "TrackButton"), for: .normal)
        friendListButton.setImage(#imageLiteral(resourceName: "FriendListButton"), for: .normal)
        
        ViewController.sharedInstance = self
        
        // Do any additional setup after loading the view, typically from a nib.
        if ( UserDefaults.standard.bool(forKey: "HasAskedForHelp") == true ) {
            print("in danger status")
//            redButton.setTitle("Safe Now", for: .normal)
            redButton.setImage(#imageLiteral(resourceName: "StopTrackButton"), for: .normal)
            friendListButton.setImage(#imageLiteral(resourceName: "FriendsMapButton"), for: .normal)
            secondLabel.isHidden = true
            clockLabel.isHidden = true
            firstLabel.text = "Tap to stop share location."
            
            AppDelegate.shared().sendNotification = true
            AppDelegate.shared().refreshingLocation = UserDefaults.standard.bool(forKey: "HasAskedForHelp")
            AppDelegate.shared().refreshLocation()

            DispatchQueue.main.async {
                UIApplication.shared.perform(#selector(URLSessionTask.suspend))
            }
        } else {
            viewTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.tickDown), userInfo: nil, repeats: true)
            print("not in danger statue")
//            redButton.setTitle("TrackMe", for: .normal)
            redButton.setImage(#imageLiteral(resourceName: "TrackButton"), for: .normal)
            friendListButton.setImage(#imageLiteral(resourceName: "FriendListButton"), for: .normal)
            secondLabel.isHidden = false
            clockLabel.isHidden = false
            firstLabel.text = "Autorun after"
        }
    }
    
    override func viewWillLayoutSubviews() {
        if (ViewController.sharedInstance?.didTapNotification)! {
            DispatchQueue.main.async {
                self.viewTimer.invalidate()
                self.performSegue(withIdentifier: "tappedNotificationSegue", sender: nil)
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func saveMeButtonTapped(_ sender: Any?) {
        if ( UserDefaults.standard.bool(forKey: "HasAskedForHelp") == false ) {
            UserDefaults.standard.set(true, forKey: "HasAskedForHelp")
            print("SaveMe button tapped")
//            redButton.setTitle("Safe Now", for: .normal)
            redButton.setImage(#imageLiteral(resourceName: "StopTrackButton"), for: .normal)
            friendListButton.setImage(#imageLiteral(resourceName: "FriendsMapButton"), for: .normal)
            secondLabel.isHidden = true
            clockLabel.isHidden = true
            firstLabel.text = "Tap to stop share location."
            
            viewTimer.invalidate()
            AppDelegate.shared().sendNotification = true
            AppDelegate.shared().refreshingLocation = UserDefaults.standard.bool(forKey: "HasAskedForHelp")
            AppDelegate.shared().refreshLocation()
            
            DispatchQueue.main.async {
                UIApplication.shared.perform(#selector(URLSessionTask.suspend))
            }
        } else {
            UserDefaults.standard.set(false, forKey: "HasAskedForHelp")
            print("Safe Now button tapped")
//            redButton.setTitle("TrackMe", for: .normal)
            redButton.setImage(#imageLiteral(resourceName: "TrackButton"), for: .normal)
            friendListButton.setImage(#imageLiteral(resourceName: "FriendListButton"), for: .normal)
            secondLabel.isHidden = false
            clockLabel.isHidden = false
            firstLabel.text = "Autorun after"
            
            AppDelegate.shared().stopRefreshLocation()
            let ref_lov = Database.database().reference().child("users").child(User.current.uid).child("location")
            ref_lov.setValue(nil)
            
            myTimeCoumnt = 24
            clockLabel.text = String(myTimeCoumnt)
            viewTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.tickDown), userInfo: nil, repeats: true)
        }

    }

    @IBAction func setButtonTapped(_ sender: Any?) {
        print("Setting button tapper")
        if ( UserDefaults.standard.bool(forKey: "HasAskedForHelp") == false ) {
            print("go to friend list")
            if let timer  = self.viewTimer {
                timer.invalidate()
            }
            self.performSegue(withIdentifier: "toFriendsList", sender: nil)
        } else {
            print("go to friend map")
            if let timer = self.viewTimer {
                timer.invalidate()
            }
            self.performSegue(withIdentifier: "toFriendsMap", sender: nil)
        }
    }
    
    //MARK: - IBAction func unwindToListNotesViewController
    @IBAction func unwindToViewController(_ segue: UIStoryboardSegue) {
        myTimeCoumnt = 24
        clockLabel.text = String(myTimeCoumnt)
        if ( UserDefaults.standard.bool(forKey: "HasAskedForHelp") == false ) {
            viewTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.tickDown), userInfo: nil, repeats: true)
        }
        
    }
    
    func tickDown() {
        print("\(myTimeCoumnt)")
        clockLabel.text = String(myTimeCoumnt)
        myTimeCoumnt = myTimeCoumnt - 1
        
        if ( myTimeCoumnt == -1 ) {
            self.viewTimer.invalidate()
            self.saveMeButtonTapped(nil)
        }
    }
    
}

