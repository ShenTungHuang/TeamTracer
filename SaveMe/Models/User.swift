//
//  User.swift
//  SaveMe
//
//  Created by STH on 2017/7/10.
//  Copyright © 2017年 STH. All rights reserved.
//

import Foundation
import FirebaseDatabase.FIRDataSnapshot
import FirebaseDatabase

struct Friend {
    var userNmae: String
    var dispName: String
    var sendSet: Bool
    var uid: String
    var tok: String
    var inDanger: Bool
}

class User: NSObject {
    
    // MARK: - Properties
    let uid: String
    let username: String
    var friends = [Friend]()
    
    // MARK: - Singleton
    private static var _current: User?
    
    static var current: User {
        guard let currentUser = _current else {
            fatalError("Error: current user doesn't exist")
        }
        
        return currentUser
    }
    
    // MARK: - Init
    init(uid: String, username: String) {
        self.uid = uid
        self.username = username
        super.init()
    }
    
    init?(snapshot: DataSnapshot, completion: @escaping (User) -> ()) {
        guard let dict = snapshot.value as? [String : Any],
            let username = dict["username"] as? String
            else { return nil }
        
        self.uid = snapshot.key
        self.username = username
        
        super.init()
        var pendingCallCounter = 0
        
        if let friendname = dict["friends"] as? [String : Any] {
            for key in Array(friendname.keys) {
                pendingCallCounter += 1
                let temp = friendname[key] as? [String : Any]
                
                let ref_loc = Database.database().reference().child("users").child((temp?["uid"] as? String)!).child("location/latitude")
                ref_loc.observeSingleEvent(of: .value, with: { (data) in
                    if (data.value as? Float) != nil {
                        print("with location root")
                        self.friends.append(Friend(userNmae: key, dispName: (temp?["dispname"] as? String)!, sendSet: (temp?["send"] as? Bool)!, uid: (temp?["uid"] as? String)!, tok: (temp?["tok"] as? String)!, inDanger: true))

                    } else {
                        print("without location root")
                        self.friends.append(Friend(userNmae: key, dispName: (temp?["dispname"] as? String)!, sendSet: (temp?["send"] as? Bool)!, uid: (temp?["uid"] as? String)!, tok: (temp?["tok"] as? String)!, inDanger: false))
                    }
                    pendingCallCounter -= 1
                    if ( pendingCallCounter == 0 ) {
                        completion(self)
                    }
                })
                
            }
            
        } else {
            completion(self)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        guard let uid = aDecoder.decodeObject(forKey: Constants.UserDefaults.uid) as? String,
            let username = aDecoder.decodeObject(forKey: Constants.UserDefaults.username) as? String
            else { return nil }
        
        self.uid = uid
        self.username = username
        
        super.init()
    }
    
    // MARK: - Class Methods
    static func setCurrent(_ user: User, writeToUserDefaults: Bool = false) {
        if writeToUserDefaults {
            let data = NSKeyedArchiver.archivedData(withRootObject: user)
            
            UserDefaults.standard.set(data, forKey: Constants.UserDefaults.currentUser)
            
            UserDefaults.standard.set(false, forKey: "HasAskedForHelp")
        }
        
        _current = user
    }
    
}

extension User: NSCoding {
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(uid, forKey: Constants.UserDefaults.uid)
        aCoder.encode(username, forKey: Constants.UserDefaults.username)
    }
    
}
