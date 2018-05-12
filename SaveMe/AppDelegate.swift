//
//  AppDelegate.swift
//  SaveMe
//
//  Created by STH on 2017/7/10.
//  Copyright © 2017年 STH. All rights reserved.
//

import UIKit
import Firebase
import FirebaseCore
import UserNotifications
import FirebaseInstanceID
import FirebaseMessaging
import GoogleMaps
import GooglePlaces
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {

    var window: UIWindow?
    let gcmMessageIDKey = "gcm.message_id"
    var delegateTimer:Timer!
    var refreshingLocation: Bool = false
    var backgroundTaskIdentifier: UIBackgroundTaskIdentifier?
    
    // for google map
    var locationManager = CLLocationManager()
    
    var sendNotification: Bool = false
    
    // MARK: - Core Data stack
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "SaveMe")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // for firebase
        FirebaseApp.configure()
        // keep user login
        configureInitialRootViewController(for: window)
        // for IQ key board
        IQKeyboardManager.sharedManager().enable = true
        // for google map api
        GMSServices.provideAPIKey(Constants.License.google)
        GMSPlacesClient.provideAPIKey(Constants.License.google)
        
        // for push notification
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(options: authOptions, completionHandler: {_, _ in })
            
            // For iOS 10 data message (sent via FCM)
            Messaging.messaging().delegate = self
            
        } else {
            let settings: UIUserNotificationSettings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        application.registerForRemoteNotifications()
        
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.tokenRefreshNotification), name: Notification.Name.MessagingRegistrationTokenRefreshed, object: nil)
        
        return true
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        
        completionHandler(UIBackgroundFetchResult.newData)
    }
    
    func tokenRefreshNotification(_ notification: Notification) {
        if let refreshedToken = InstanceID.instanceID().token() {
            print("InstanceID token: \(refreshedToken)")
        }
        
        // Connect to FCM since connection may have failed when attempted before having a token.
        connectToFcm()
    }
    
    func connectToFcm() {
        // Won't connect since there is no token
        guard InstanceID.instanceID().token() != nil else {
            return
        }
        
        // Disconnect previous FCM connection if it exists.
        Messaging.messaging().shouldEstablishDirectChannel = false
        
        Messaging.messaging().shouldEstablishDirectChannel = true // for swift4 Xcode9
        
        // for swift3, Xcode8
//        Messaging.messaging().connect { (error) in
//            if error != nil {
//                print("Unable to connect with FCM. \(error?.localizedDescription ?? "")")
//            } else {
//                print("Connected to FCM.")
//            }
//        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
//        print("Unable to register for remote notifications: \(error.localizedDescription)")
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
//        print("APNs token retrieved: \(deviceToken)")
        
        // With swizzling disabled you must set the APNs token here.
        // FIRInstanceID.instanceID().setAPNSToken(deviceToken, type: FIRInstanceIDAPNSTokenType.sandbox)
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        connectToFcm()
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        Messaging.messaging().shouldEstablishDirectChannel = false
//        print("Disconnected from FCM.")
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
//        print("terminate app")
        
        let ref_lov = Database.database().reference().child("users").child(User.current.uid).child("location")
        ref_lov.setValue(nil)
    }
    
    func tickDown() {
//        print("appdelegate tick")
        
        if ( refreshingLocation == true ) {
            // feedback Location
            locationManager.delegate = self
            locationManager.requestWhenInUseAuthorization()
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
            
            if let location = locationManager.location {
                let loc = ["latitude": location.coordinate.latitude, "longitude": location.coordinate.longitude]
                let ref_loc = Database.database().reference().child("users").child(User.current.uid).child("location")
                
                ref_loc.setValue(loc, withCompletionBlock: {(error, ref) in
                  //it runs the code in here only after the user has written something to firebase
                    if ( self.sendNotification == true ) {
                        self.sendNotification = false
                        self.senfNotification()
                    }
                })
                
                
//                print("refresh location")
            }
        }
    }
    
    func refreshLocation() {
        locationManager.allowsBackgroundLocationUpdates = true
        backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(expirationHandler: {
            UIApplication.shared.endBackgroundTask(self.backgroundTaskIdentifier!)
        })
        delegateTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.tickDown), userInfo: nil, repeats: true)
    }
    
    func stopRefreshLocation() {
        locationManager.allowsBackgroundLocationUpdates = false
        delegateTimer.invalidate()
        refreshingLocation = false
    }
    
    static func shared() -> AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
    
    func senfNotification() {
        getTok() { (list) in
//            print(list)
            for ii in list {
                let url = NSURL(string: "https://fcm.googleapis.com/fcm/send")!
                let session = URLSession.shared
                
                let request = NSMutableURLRequest(url: url as URL)
                request.httpMethod = "POST"
                request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringCacheData
                
                let dictionary = ["to": ii,"priority": "high", "time_to_live": 259200, "notification":["body": "I need your help, you can track my location now!","title": "Please track my location", "sound": "default"]] as [String : Any]
//                print(dictionary)
                do {
                    try request.httpBody = JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted)
                } catch {
//                    print("fail to add JSON data")
                }
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.addValue(Constants.License.fireBase, forHTTPHeaderField: "Authorization")
                
                let task = session.dataTask(with: request as URLRequest, completionHandler: {data, response, error -> Void in
                    print("Response: \(String(describing: response))")
                    let strData = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
                    print("Body: \(String(describing: strData))")
                    print("Error: \(String(describing: error))")
                    var json = NSDictionary()
                    do { json = try JSONSerialization.jsonObject(with: data!, options: .mutableLeaves) as! NSDictionary } catch {}
                    let parseJSON = json
                    let success = parseJSON["success"] as? Int
                    print("Success: \(String(describing: success))")
                })
                task.resume()
            }
        }
    }
    
    func getTok(completion: @escaping ([String]) -> Void) {
        var returnTok = [String]()
        let ref = Database.database().reference().child("users").child(User.current.uid).child("friends")
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if let friendlist = snapshot.children.allObjects as? [DataSnapshot] {
                for friend in friendlist {
                    if let Dict = friend.value as? [String : Any] {
                        if ( (Dict["send"] as? Bool)! ) {
                            returnTok.append((Dict["tok"] as? String)!)
                        }
                    }
                }
                completion(returnTok)
            }
        })
    }
    
}

extension AppDelegate {
    
    func configureInitialRootViewController(for window: UIWindow?) {
        let defaults = UserDefaults.standard
        let initialViewController: UIViewController
        
        if Auth.auth().currentUser != nil,
            let userData = defaults.object(forKey: Constants.UserDefaults.currentUser) as? Data,
            let user = NSKeyedUnarchiver.unarchiveObject(with: userData) as? User {
            
            User.setCurrent(user)
            
            initialViewController = UIStoryboard.initialViewController(for: .main)
        } else {
            initialViewController = UIStoryboard.initialViewController(for: .login)
        }
        
        window?.rootViewController = initialViewController
        window?.makeKeyAndVisible()
    }
    
}

@available(iOS 10, *)
extension AppDelegate: UNUserNotificationCenterDelegate {
    
    // Receive displayed notifications for iOS 10 devices.
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        
        // Change this to your preferred presentation option
        // 設置通知的選項
        completionHandler(UNNotificationPresentationOptions.alert)
        
        
        DispatchQueue.main.async {
            ListTableViewController.sharedInstance?.retrieveData()
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        
        completionHandler()
        
        ViewController.sharedInstance?.didTapNotification = true
    }
}

extension AppDelegate: MessagingDelegate {
    
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
//        print("received")
    } // add by Grant Goodman 2017/7/17
    
    func messaging(_ messaging: Messaging, didRefreshRegistrationToken fcmToken: String) {
//        print("refreshed")
    } // add by Grant Goodman 2017/7/17
    
    // Receive data message on iOS 10 devices while app is in the foreground.
    func application(received remoteMessage: MessagingRemoteMessage) {
        print(remoteMessage.appData)
    }
}
