//
//  MapViewController.swift
//  SaveMe
//
//  Created by STH on 2017/7/21.
//  Copyright © 2017年 STH. All rights reserved.
//

import UIKit
import GoogleMaps
import FirebaseDatabase

class MapViewController: UIViewController, CLLocationManagerDelegate {
    
    // for google map
    var locationManager = CLLocationManager()
    lazy var mapView = GMSMapView()
    var marker = GMSMarker()
    // timer
    var timer:Timer!
    // friend info
    var uid: String?
    var dispname: String?
    // location
    var latitude: Float?
    var longitude: Float?
    
    var loseLocation: Bool = false

    lazy var locationButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
//        button.setTitle("Location", for: .normal)
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

        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.tickDown), userInfo: nil, repeats: true)
        
        setupLocationButton()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if ( loseLocation == true && identifier == "mapToListView" ) {
            let alertController = UIAlertController(title: "Warning !", message: "Will lose final location if leave now.", preferredStyle: UIAlertControllerStyle.alert)
            let gobut = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (action: UIAlertAction!) in
                self.performSegue(withIdentifier: "mapToListView", sender: nil)
            })
            let cancelbut = UIAlertAction(title: "CANCEL", style: UIAlertActionStyle.destructive, handler: { (action: UIAlertAction!) in
                print("do nothing")
            })
            alertController.addAction(gobut)
            alertController.addAction(cancelbut)
            self.present(alertController, animated: true, completion: nil)
            
            return false
        } else {
            return true
        }
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("map to list")
        latitude = nil
        longitude = nil
//        uid = nil
//        dispname = nil
    }
    
    func locationButtonTapper() {
        print("print all location")
        if let location = locationManager.location {
            let temp_latitude = ( latitude! + Float(location.coordinate.latitude) ) / 2
            let temp_longitude = ( longitude! + Float(location.coordinate.longitude) ) / 2
            let dist = location.distance(from: CLLocation(latitude: CLLocationDegrees(latitude!), longitude: CLLocationDegrees(longitude!)))
            let  zoomSize: Float = getZoomSize(distance: Float(dist))

            let camera = GMSCameraPosition.camera(withLatitude: CLLocationDegrees(temp_latitude), longitude: CLLocationDegrees(temp_longitude), zoom: zoomSize)
            mapView.isMyLocationEnabled = true
            mapView.camera = camera
            
            setupLocationButton()
        }
    }
    
    func setupLocationButton() {
        self.mapView.addSubview(locationButton)
        
        locationButton.addTarget(self, action: #selector(locationButtonTapper), for: .touchUpInside)
        locationButton.heightAnchor.constraint(equalToConstant: 100).isActive = true
        locationButton.widthAnchor.constraint(equalToConstant: 100).isActive = true
        locationButton.rightAnchor.constraint(equalTo: self.mapView.rightAnchor, constant: 8).isActive = true
        locationButton.bottomAnchor.constraint(equalTo: self.mapView.bottomAnchor, constant: 8).isActive = true
        
    }
    
    func tickDown() {
        let ref_loc = Database.database().reference().child("users").child(self.uid!).child("location")
        ref_loc.observeSingleEvent(of: .value, with: { (snapshot) in
            if let loc = snapshot.value as? [String : Any] {
                self.latitude = (loc["latitude"] as? Float)!
                self.longitude = (loc["longitude"] as? Float)!
                //print("latitude: \(self.latitude), longitude: \(self.longitude)")

                self.marker.position = CLLocationCoordinate2D(latitude: CLLocationDegrees(self.latitude!), longitude: CLLocationDegrees(self.longitude!))
                self.marker.title = self.dispname
                self.marker.map = self.mapView
                
                if ( self.loseLocation == true ) {
                    let alertController: UIAlertController
                    alertController = UIAlertController(title: "Great !", message: "\"\(self.dispname!)\" re-update new location.", preferredStyle: UIAlertControllerStyle.alert)
                    let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: {(alert :UIAlertAction!) in
                        print("OK button tapped")
                    })
                    alertController.addAction(okAction)
                    self.present(alertController, animated: true, completion: nil)
                    
                    self.loseLocation = false
                }
            } else {
                if ( self.loseLocation == false ) {
                    let alertController: UIAlertController
                    alertController = UIAlertController(title: "Sorry !", message: "\"\(self.dispname!)\" doesn't update new location.", preferredStyle: UIAlertControllerStyle.alert)
                    let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: {(alert :UIAlertAction!) in
                        print("OK button tapped")
                    })
                    alertController.addAction(okAction)
                    self.present(alertController, animated: true, completion: nil)
                    self.loseLocation = true
                }
            }
        })
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
    
    //    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    //        let userLocation = locations.last
    //        let camera = GMSCameraPosition.camera(withLatitude: userLocation!.coordinate.latitude,
    //                                              longitude: userLocation!.coordinate.longitude,
    //                                              zoom: 13.0)
    //        mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
    //        mapView.isMyLocationEnabled = true
    //
    //        DispatchQueue.main.async {
    //            self.view = self.mapView
    //        }
    //
    //        locationManager.stopUpdatingLocation()
    //    }
    
}
