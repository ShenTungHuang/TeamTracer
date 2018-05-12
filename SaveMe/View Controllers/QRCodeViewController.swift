//
//  QRCodeViewController.swift
//  SaveMe
//
//  Created by STH on 2017/7/11.
//  Copyright © 2017年 STH. All rights reserved.
//

import UIKit
import AVFoundation
import FirebaseStorage
import FirebaseDatabase
import FirebaseInstanceID

class QRCodeViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

    /* UI button */
    @IBOutlet weak var showQRCodeButton: UIButton!
    @IBOutlet weak var navigationTitle: UINavigationItem!
    /* Show QR Code */
    @IBOutlet weak var imgQRCode: UIImageView!
    var qrcodeImage: CIImage!
    /* QR Code Reader */
    var captureSession:AVCaptureSession?
    var videoPreviewLayer:AVCaptureVideoPreviewLayer?
    var qrCodeFrameView:UIView?
    let supportedCodeTypes = [AVMetadataObjectTypeUPCECode,
                              AVMetadataObjectTypeCode39Code,
                              AVMetadataObjectTypeCode39Mod43Code,
                              AVMetadataObjectTypeCode93Code,
                              AVMetadataObjectTypeCode128Code,
                              AVMetadataObjectTypeEAN8Code,
                              AVMetadataObjectTypeEAN13Code,
                              AVMetadataObjectTypeAztecCode,
                              AVMetadataObjectTypePDF417Code,
                              AVMetadataObjectTypeQRCode]
    /* new friend information */
    var numberOfFriend: Int = 0
    var newFried: Friend? {
        didSet {
            // use unwind segue go back to list view
            if ( self.newFried != nil ) {
                self.performSegue(withIdentifier: "qrcancel", sender: nil)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Get an instance of the AVCaptureDevice class to initialize a device object and provide the video as the media type parameter.
        let captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        
        do {
            // Get an instance of the AVCaptureDeviceInput class using the previous device object.
            let input = try AVCaptureDeviceInput(device: captureDevice)
            
            // Initialize the captureSession object.
            captureSession = AVCaptureSession()
            
            // Set the input device on the capture session.
            captureSession?.addInput(input)
            
            // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession?.addOutput(captureMetadataOutput)
            
            // Set delegate and use the default dispatch queue to execute the call back
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = supportedCodeTypes
            
            // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspect
            videoPreviewLayer?.frame = view.layer.bounds
            view.layer.addSublayer(videoPreviewLayer!)
            
            // Start video capture.
            captureSession?.startRunning()
            
            // Move the message label and top bar to the front
            view.bringSubview(toFront: showQRCodeButton)
        } catch {
            // If any error occurs, simply print it out and don't continue any more.
            print(error)
            return
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if let identifier = segue.identifier {
            if identifier == "qrcancel" {
//                print("Cancel button in qr code tapped")
            }
        }
    }
    
    @IBAction func qrButtonTapped(_ sender: UIButton) {
        let buttonText: String = (showQRCodeButton.titleLabel?.text)!
        // Stop video capture.
        if ( buttonText == "My QR Code" ) {
            captureSession?.stopRunning()
            videoPreviewLayer?.removeFromSuperlayer()
            showQRCode()
            showQRCodeButton.setTitle("QR Code Reader", for: .normal)
            navigationTitle.title = "My QR Code"

            let wait = Database.database().reference().child("users").child(User.current.uid).child("friends")
            wait.observe(.childAdded, with: { (snapshot) in
                wait.observeSingleEvent(of: .value, with: { (DataSnapshot) in
                    let friendNumber = Int(DataSnapshot.childrenCount)
                    if ( friendNumber > self.numberOfFriend ) {
                        let value = snapshot.value as? NSDictionary
                        self.newFried = Friend(userNmae: value?["dispname"]! as! String, dispName: value?["dispname"]! as! String, sendSet: value?["send"]! as! Bool, uid: value?["uid"]! as! String, tok: value?["tok"]! as! String, inDanger: false)
//                        print("be scaned")
                    }
                })
            })
        } else {
            imgQRCode.image = nil
            self.viewDidLoad()
            showQRCodeButton.setTitle("My QR Code", for: .normal)
            navigationTitle.title = "QR Code Reader"
        }
        
    }
    
    // MARK: - AVCaptureMetadataOutputObjectsDelegate Methods
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        
        // Check if the metadataObjects array is not nil and it contains at least one object.
        if metadataObjects == nil || metadataObjects.count == 0 {
            qrCodeFrameView?.frame = CGRect.zero
            // showQRCodeButton.setTitle("No QR code is detected", for: .normal)
            return
        }
        
        // Get the metadata object.
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        if metadataObj.type == AVMetadataObjectTypeQRCode {
            // If the found metadata is equal to the QR code metadata then update the status label's text and set the bounds
            let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
            qrCodeFrameView?.frame = barCodeObject!.bounds
            
            if metadataObj.stringValue != nil {
//                print("scane QR code")
                addNewFriend(newUid: metadataObj.stringValue!)
            }
        }
    }
    
    func showQRCode() {
        if qrcodeImage == nil {
            let data = User.current.uid.data(using: String.Encoding.isoLatin1, allowLossyConversion: false)

            let filter = CIFilter(name: "CIQRCodeGenerator")
            filter?.setValue(data, forKey: "inputMessage")
            filter?.setValue("Q", forKey: "inputCorrectionLevel")

            qrcodeImage = filter?.outputImage
            
            let scaleX = imgQRCode.frame.size.width / qrcodeImage.extent.width
            let scaleY = imgQRCode.frame.size.height / qrcodeImage.extent.height
            
            let transformedImage = qrcodeImage.applying(CGAffineTransform(scaleX: scaleX, y: scaleY))
            imgQRCode.image = UIImage(ciImage: transformedImage)
            qrcodeImage = transformedImage
            
        } else {
            imgQRCode.image = UIImage(ciImage: qrcodeImage)
        }
    }
    
    func addNewFriend(newUid: String) {
//        print("add new friend")
        captureSession?.stopRunning()
        videoPreviewLayer?.removeFromSuperlayer()
        // user A (scanner)
        let ref = Database.database().reference().child("users").child(newUid).child("username")
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            let friendName = (snapshot.value as? String)!
            
            var tok: String?
            let ref_tok = Database.database().reference().child("users").child(newUid).child("tok")
            ref_tok.observeSingleEvent(of: .value, with: { (snapshot_tok) in
                tok = (snapshot_tok.value as? String)!
                
                let ref_save = Database.database().reference().child("users").child(User.current.uid).child("friends").child(friendName)
                let saveData = ["dispname": friendName, "send": true, "uid": newUid, "tok": tok!] as [String : Any]
                ref_save.setValue(saveData)
                
                self.newFried = Friend(userNmae: friendName, dispName: friendName, sendSet: true, uid: newUid, tok: InstanceID.instanceID().token()!, inDanger: false)
                
                // user B (qr code)
                let ref_save2 = Database.database().reference().child("users").child(newUid).child("friends").child(User.current.username)
                let saveData2 = ["dispname": User.current.username, "send": true, "uid": User.current.uid, "tok": InstanceID.instanceID().token()!] as [String : Any]
                ref_save2.setValue(saveData2)
            })
        })
    }

}
