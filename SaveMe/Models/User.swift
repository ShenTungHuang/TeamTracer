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

class User: NSObject {
    
    // MARK: - Properties
    let uid: String
    let username: String
    
    // MARK: - Init
    init(uid: String, username: String) {
        self.uid = uid
        self.username = username
        super.init()
    }
    
    init?(snapshot: DataSnapshot) {
        guard let dict = snapshot.value as? [String : Any],
            let username = dict["username"] as? String
            else { return nil }
        
        self.uid = snapshot.key
        self.username = username
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        guard let uid = aDecoder.decodeObject(forKey: Constants.UserDefaults.uid) as? String,
            let username = aDecoder.decodeObject(forKey: Constants.UserDefaults.username) as? String
            else { return nil }
        
        self.uid = uid
        self.username = username
        
        super.init()
    }
    
    // MARK: - Singleton
    private static var _current: User?

    static var current: User {
        guard let currentUser = _current else {
            fatalError("Error: current user doesn't exist")
        }

        return currentUser
    }
    
    // MARK: - Class Methods
    static func setCurrent(_ user: User, writeToUserDefaults: Bool = false) {
        if writeToUserDefaults {
            let data = NSKeyedArchiver.archivedData(withRootObject: user)
 
            UserDefaults.standard.set(data, forKey: Constants.UserDefaults.currentUser)
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
