//
//  SCPViewController.swift
//  SwiftCameraPicker
//
//  Created by Alin Paulesc on 25/07/16.
//  Copyright © 2016 codenapse. All rights reserved.
//

import UIKit
import CameraManager
import Photos


public final class SCPViewController: UIViewController, SCPCameraViewDelegate {
    
    public var mediaFilesFromSession: [UIImage] = []
    lazy var delegate: SCPViewControllerCaptureDelegate! = nil
    
    @IBOutlet var headerCancelButton: UIButton!
    @IBOutlet var headerDoneButton: UIButton!
    
    var collectionViewContainer: UIView!
    lazy var collectionView = SCPCollectionView.instance()
    //
    @IBOutlet var cameraViewContainer: UIView!
    lazy var cameraView = SCPCameraView.instance()
    //
    //
    override public func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        let navbar = self.navigationController?.navigationBar
        navbar?.barStyle = UIBarStyle.Black
        navbar?.tintColor = UIColor.whiteColor()
    }
    //
    //
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self.cameraViewContainer.backgroundColor = UIColor.blackColor()
        self.cameraView.initialize()
        self.cameraView.cameraViewDelegate = self
        self.cameraViewContainer.addSubview(cameraView)
        
        self.collectionViewContainer = self.view.viewWithTag(10)! as UIView
        self.collectionView.initialize()
        self.collectionViewContainer.addSubview(collectionView)
        
        
        self.view.layoutIfNeeded()
        // Do any additional setup after loading the view.
    }
    //
    //
    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    //
    //
    override public func loadView() {
//        print("SCPViewController -> override public func loadView()")
        if let view = UINib(nibName: "SCPViewController",
                            bundle: NSBundle(forClass: self.classForCoder))
                            .instantiateWithOwner(self, options: nil).first as? UIView { self.view = view }
    }
    //
    //
    //
    
    @IBAction func headerCancelButtonPressed(sender: UIButton) {
        self.dismissViewControllerAnimated(false, completion: nil)
    }
    @IBAction func headerDoneButtonPressed(sender: AnyObject) {
        let mediaFiles = self.collectionView.getMediaFilesFromSession()
        for media in mediaFiles {
            if media.deletedToggle == false {
                self.mediaFilesFromSession.append(media.image)
            }
        }
        self.delegate.capturedMediaFilesFromSession(self.mediaFilesFromSession)
        self.dismissViewControllerAnimated(false, completion: nil)
    }
    //
    // MARK: - SCPCameraViewDelegate
    //
    func cameraShotFinished(image: UIImage) {
//        print("SCPViewController -> cameraShotFinished()")
        self.collectionView.addMediaFileToCollection(image)
    }
    //
    //
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

protocol SCPViewControllerCaptureDelegate: class {
    func capturedMediaFilesFromSession(mediaFiles: [UIImage])
}
