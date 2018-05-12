//
//  ListTableViewController.swift
//  SaveMe
//
//  Created by STH on 2017/7/11.
//  Copyright © 2017年 STH. All rights reserved.
//

import UIKit
import FirebaseDatabase.FIRDataSnapshot
import FirebaseDatabase

class ListTableViewController: UITableViewController {
    
    var friends = [Friend]() {
        didSet {
            tableView.reloadData()
            if ( newFriend != nil ) {
                self.performSegue(withIdentifier: "toEditSegue", sender: nil)
            }
        }
    }
    
    var gotNewFiend: Bool = false
    var newFriend: Friend?
    
    // Singleton?
    static var sharedInstance: ListTableViewController?
    var getNotification: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        ListTableViewController.sharedInstance = self
        
        ViewController.sharedInstance?.didTapNotification = false
        
        self.navigationController?.navigationBar.barTintColor = UIColor.init(red: CGFloat((0xE0E0E0 & 0xFF0000) >> 16)/255.0, green: CGFloat((0xE0E0E0 & 0xFF00) >> 8)/255.0, blue: CGFloat(0xE0E0E0 & 0xFF)/255.0, alpha: 1)
        self.navigationController?.navigationBar.tintColor = UIColor.init(red: CGFloat((0x424242 & 0xFF0000) >> 16)/255.0, green: CGFloat((0x424242 & 0xFF00) >> 8)/255.0, blue: CGFloat(0x424242 & 0xFF)/255.0, alpha: 1)
        retrieveData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.friends.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "listTableViewCell", for: indexPath) as! ListTableViewCell
        
        // Configure the cell...
        let row = indexPath.row
        cell.listNameLabel.text = self.friends[row].dispName
        if ( self.friends[row].inDanger ) {
            cell.backgroundColor = UIColor.init(red: CGFloat((0xEF9A9A & 0xFF0000) >> 16)/255.0, green: CGFloat((0xEF9A9A & 0xFF00) >> 8)/255.0, blue: CGFloat(0xEF9A9A & 0xFF)/255.0, alpha: 1)
        } else {
            cell.backgroundColor = UIColor.init(red: CGFloat((0xEEEEEE & 0xFF0000) >> 16)/255.0, green: CGFloat((0xEEEEEE & 0xFF00) >> 8)/255.0, blue: CGFloat(0xEEEEEE & 0xFF)/255.0, alpha: 1)
        }
        
        return cell
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            let delref = Database.database().reference().child("users").child(User.current.uid).child("friends").child(friends[indexPath.row].userNmae)
            delref.setValue(nil)
            
            retrieveData()
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if ( friends[indexPath.row].inDanger ) {
            performSegue(withIdentifier: "toMapSegue", sender: nil)
        } else {
            performSegue(withIdentifier: "toEditSegue", sender: nil)
        }
    }
    
    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if let identifier = segue.identifier {
            if ( gotNewFiend == true ) {
                gotNewFiend = false
                let addFriendViewController = segue.destination as! AddFriendViewController
                addFriendViewController.username = (newFriend?.userNmae)!
                addFriendViewController.dispname = (newFriend?.userNmae)!
                addFriendViewController.send_b = true
                newFriend = nil
            } else if ( identifier == "toEditSegue" ) {
//                print("goto friend setting")
                let indexPath = tableView.indexPathForSelectedRow!.row
                let addFriendViewController = segue.destination as! AddFriendViewController
                addFriendViewController.username = self.friends[indexPath].userNmae
                addFriendViewController.dispname = self.friends[indexPath].dispName
                addFriendViewController.send_b = self.friends[indexPath].sendSet
            } else if ( identifier == "gotoQR" ) {
                        let qrViewController = segue.destination as! QRCodeViewController
                        qrViewController.numberOfFriend = self.friends.count
            } else if ( identifier == "toMapSegue" ) {
//                print("goto map")
                let indexPath = tableView.indexPathForSelectedRow!.row
                let mpaViewController = segue.destination as! MapViewController
                mpaViewController.uid = self.friends[indexPath].uid
                mpaViewController.dispname = self.friends[indexPath].dispName
            }
        }
        
    }
    
    //MARK: - IBAction func unwindToListNotesViewController
    @IBAction func unwindToListViewController(_ segue: UIStoryboardSegue) {
        retrieveData()
        if let identifier = segue.identifier {
            if ( identifier == "qrcancel" ) {
//                print("back from qr cancel")
                if let qrViewController = segue.source as? QRCodeViewController {
                    let dataRecieved = qrViewController.newFried
                    if ( dataRecieved != nil ) {
//                        print("good")
                        gotNewFiend = true
                        newFriend = dataRecieved
                        qrViewController.newFried = nil
                    }
                }
            } else if ( identifier == "setunwindsegue" ) {
//                print("set tapped and back")
                newFriend = nil
            } else if ( identifier == "mapToListView" ) {
            }
        }
    }
    
    func retrieveData() {
        let ref = Database.database().reference().child("users").child(User.current.uid)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            User(snapshot: snapshot, completion: { (user) in
                self.friends = user.friends
            })
        })
    }

}
