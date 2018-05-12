//
//  FriendMapViewController.swift
//  SaveMe
//
//  Created by STH on 2017/8/4.
//  Copyright © 2017年 STH. All rights reserved.
//

import UIKit
import GoogleMaps
import FirebaseDatabase

struct FriendLocation {
    var latitude: CLLocationDegrees? = nil
    var longitude: CLLocationDegrees? = nil
    var dispname: String
}

class FriendMapViewController: UIViewController, CLLocationManagerDelegate {

    // for google map
    var locationManager = CLLocationManager()
    lazy var mapView = GMSMapView()
    var markers = [GMSMarker]()
    // timer
    var timer:Timer!
    // for scale
    var longestDistance: Float = 0
    
    var trackers = [FriendLocation]()
    
    lazy var locationButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        button.setImage(#imageLiteral(resourceName: "ViewButton"), for: .normal)
        button.setTitleColor(UIColor.black, for: .normal)
        button.isUserInteractionEnabled = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // User Location
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        
        if let location = locationManager.location {
            let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude, longitude: location.coordinate.longitude, zoom: 13.0)
            mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
            mapView.isMyLocationEnabled = true
            view = mapView
        }
        
        setupLocationButton()
        
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.tickDown), userInfo: nil, repeats: true)

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        print("friend map to list")
        if ( timer.isValid ) {
            timer.invalidate()
        }
    }
    
    func tickDown() {
//        print("friends map tickDown")
        
        getTrackers()
    }
    
    func getTrackers() {
        trackers = [FriendLocation]()
        
        let ref = Database.database().reference().child("users").child(User.current.uid).child("friends")
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if let friendlist = snapshot.children.allObjects as? [DataSnapshot] {
                self.longestDistance = 0
                for friend in friendlist {
                    if let Dict = friend.value as? [String : Any] {
                        if ( Dict["location"] != nil ) {
                            let loc = Dict["location"] as? [String : Any]
                            self.trackers.append(FriendLocation(latitude: CLLocationDegrees(((loc?["latitude"] as? NSNumber)?.floatValue)!), longitude: CLLocationDegrees(((loc?["longitude"] as? NSNumber)?.floatValue)!), dispname: (Dict["dispname"] as? String)!))
                            self.markers.append(GMSMarker())
                            
                            let dist = self.locationManager.location?.distance(from: CLLocation(latitude: CLLocationDegrees(((loc?["latitude"] as? NSNumber)?.floatValue)!), longitude: CLLocationDegrees(((loc?["longitude"] as? NSNumber)?.floatValue)!)))
                            self.longestDistance = (self.longestDistance > Float(dist!) * 2) ? self.longestDistance : Float(dist!) * 2
                            
//                            print("get tracking friend location")
                        } else {
                            self.trackers.append(FriendLocation(latitude: nil, longitude: nil, dispname: (Dict["dispname"] as? String)!))
                            self.markers.append(GMSMarker())
                        }
                    }
                }
                self.plotTracker()
            } else {
                self.plotTracker()
            }
        })
    }
    
    func plotTracker() {
        for (index, tracker) in trackers.enumerated() {
            if ( tracker.latitude != nil && tracker.longitude != nil ) {
                markers[index].position = CLLocationCoordinate2D(latitude: tracker.latitude!, longitude: tracker.longitude!)
                markers[index].title = tracker.dispname
                markers[index].map = self.mapView
            } else {
                markers[index].map = nil
            }
        }
    }
    
    func locationButtonTapper() {
//        print("print all location")
        if let location = locationManager.location {
            let  zoomSize: Float = getZoomSize(distance: longestDistance)
            
            let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude, longitude: location.coordinate.longitude, zoom: zoomSize)
            mapView.isMyLocationEnabled = true
            mapView.camera = camera
            
            
        }
        setupLocationButton()
    }
    
    func setupLocationButton() {
        self.mapView.addSubview(locationButton)
        
        locationButton.addTarget(self, action: #selector(locationButtonTapper), for: .touchUpInside)
        locationButton.heightAnchor.constraint(equalToConstant: 100).isActive = true
        locationButton.widthAnchor.constraint(equalToConstant: 100).isActive = true
        locationButton.rightAnchor.constraint(equalTo: self.mapView.rightAnchor, constant: 8).isActive = true
        locationButton.bottomAnchor.constraint(equalTo: self.mapView.bottomAnchor, constant: 8).isActive = true
        
    }
    
    func getZoomSize(distance dist: Float) -> Float {
        var zoomSize: Float = 1.0
        
        if ( dist <= 70.53107625 ) {
            zoomSize = 20.0
        } else if ( dist > 70.53107625 && dist <= 141.0621525 ) {
            zoomSize = 19.0
        } else if ( dist > 141.0621525 && dist <= 282.124305 ) {
            zoomSize = 18.0
        } else if ( dist > 282.124305 && dist <= 564.248610 ) {
            zoomSize = 17.0
        } else if ( dist > 564.248610 && dist <= 1128.497220 ) {
            zoomSize = 16.0
        } else if ( dist > 1128.497220 && dist <= 2256.994440 ) {
            zoomSize = 15.0
        } else if ( dist > 2256.994440 && dist <= 4513.988880 ) {
            zoomSize = 14.0
        } else if ( dist > 4513.988880 && dist <= 9027.977761 ) {
            zoomSize = 13.0
        } else if ( dist > 9027.977761 && dist <= 18055.955520 ) {
            zoomSize = 12.0
        } else if ( dist > 18055.955520 && dist <= 36111.911040 ) {
            zoomSize = 11.0
        } else if ( dist > 36111.911040 && dist <= 72223.822090 ) {
            zoomSize = 10.0
        } else if ( dist > 72223.822090 && dist <= 144447.644200 ) {
            zoomSize = 9.0
        } else if ( dist > 144447.644200 && dist <= 288895.288400 ) {
            zoomSize = 8.0
        } else if ( dist > 288895.288400 && dist <= 577790.576700 ) {
            zoomSize = 7.0
        } else if ( dist > 577790.576700 && dist <= 1155581.153000 ) {
            zoomSize = 6.0
        } else if ( dist > 1155581.153000 && dist <= 2311162.307000 ) {
            zoomSize = 5.0
        } else if ( dist > 2311162.307000 && dist <= 4622324.614000 ) {
            zoomSize = 4.0
        } else if ( dist > 4622324.614000 && dist <= 9244649.227000 ) {
            zoomSize = 3.0
        } else if ( dist > 9244649.227000 && dist <= 18489298.450000 ) {
            zoomSize = 2.0
        } else if ( dist > 18489298.450000 && dist <= 36978596.910000 ) {
            zoomSize = 1.0
        }
        
        return zoomSize
    }

}
