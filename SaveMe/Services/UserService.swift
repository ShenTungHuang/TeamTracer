//
//  UserService.swift
//  SaveMe
//
//  Created by STH on 2017/7/10.
//  Copyright © 2017年 STH. All rights reserved.
//

import Foundation
import FirebaseDatabase.FIRDataSnapshot
import FirebaseDatabase
import FirebaseInstanceID

struct UserService {
    
    static func create(_ firUser: FIRUser, username: String, completion: @escaping (User?) -> Void) {
        let userAttrs = ["username": username, "tok": InstanceID.instanceID().token()!]
        
        let ref = Database.database().reference().child("users").child(firUser.uid)
        ref.setValue(userAttrs) { (error, ref) in
//        ref.updateChildValues(userAttrs) { (error, ref) in
            if let error = error {
                assertionFailure(error.localizedDescription)
                return completion(nil)
            }
            
            ref.observeSingleEvent(of: .value, with: { (snapshot) in
                User(snapshot: snapshot, completion: { (user) in
                    completion(user)
                })
//                let user = User(snapshot: snapshot)
//                completion(user)
            })
        }
    }
    
    static func show(forUID uid: String, completion: @escaping (User?) -> Void) {
        let ref = Database.database().reference().child("users").child(uid)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            User(snapshot: snapshot, completion: { (user) in
                let ref_tok = Database.database().reference().child("users").child(uid).child("tok")
                ref_tok.setValue(InstanceID.instanceID().token()!)
                
                modifyFriendTok(tok: InstanceID.instanceID().token()!, userid: uid)

                completion(user)
            })
            completion(nil)
        })

//        let ref = Database.database().reference().child("users").child(uid)
//        ref.observeSingleEvent(of: .value, with: { (snapshot) in
//            guard let user = User(snapshot: snapshot) else {
//                return completion(nil)
//            }
//            
////            let userAttrs = ["tok": InstanceID.instanceID().token()!]
//            let ref_tok = Database.database().reference().child("users").child(uid).child("tok")
//            ref_tok.setValue(InstanceID.instanceID().token()!)
//            completion(user)
//        })
    }
    
}

func modifyFriendTok(tok: String, userid: String) {
    let ref = Database.database().reference().child("users").child(userid).child("friends")
    ref.observeSingleEvent(of: .value, with: { (DataSnapshot) in
        if let friendlist = DataSnapshot.children.allObjects as? [DataSnapshot] {
            var uidList = [String]()
            for friend in friendlist {
                if let Dict = friend.value as? [String : Any] {
                    uidList.append((Dict["uid"] as? String)!)
                }
            }
            modifyYok(tok: tok, uid: uidList)
        }
    })
}

func modifyYok(tok: String, uid: [String]) {
    for ii in uid {
        let ref = Database.database().reference().child("users").child(ii).child("friends").child(User.current.username).child("tok")
        ref.setValue(tok)
    }
}

