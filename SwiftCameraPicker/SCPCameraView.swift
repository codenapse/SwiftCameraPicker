//
//  SCPCameraView.swift
//  SwiftCameraPicker
//
//  Created by Alin Paulesc on 25/07/16.
//  Copyright © 2016 codenapse. All rights reserved.
//

import UIKit
import CameraManager

protocol SCPCameraViewDelegate: class {
    func cameraShotFinished(image: UIImage)
}

class SCPCameraView: UIView {
    
    @IBOutlet var cameraPreview: UIView!
    let cameraManager = CameraManager()
    weak var cameraViewDelegate: SCPCameraViewDelegate? = nil

    static func instance() -> SCPCameraView {
        return UINib(nibName: "SCPCameraView", bundle: NSBundle(forClass: self.classForCoder())).instantiateWithOwner(self, options: nil)[0] as! SCPCameraView
    }
    
    func initialize() {
        cameraManager.cameraOutputMode = .StillImage
        cameraManager.writeFilesToPhoneLibrary = false
        cameraManager.addPreviewLayerToView(cameraPreview)
//        print("SCPCameraView -> initialize()")
    }
    @IBAction func takePhotoBtnPressed(sender: UIButton) {
        cameraManager.capturePictureWithCompletition({ (image, error) -> Void in
            self.capturePictureCompletion(image, error: error)
        })
    }
    
    func capturePictureCompletion(image: UIImage?, error: NSError?) {
//        print("SCPCameraView -> capturePictureCompletion(image: UIImage?, error: NSError?)")
        self.cameraViewDelegate?.cameraShotFinished(image!)
    }
}

