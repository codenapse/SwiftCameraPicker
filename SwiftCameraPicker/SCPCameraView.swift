//
//  SCPCameraView.swift
//  SwiftCameraPicker
//
//  Created by Alin Paulesc on 25/07/16.
//  Copyright © 2016 codenapse. All rights reserved.
//

import UIKit
import CameraManager
import Photos

protocol SCPCollectionDelegate: class {
    func mediaFilePicked(image: UIImage)
    func mediaFileSelected(image: UIImage, phAsset: PHAsset)
    func mediaSelectedLimitReached() -> Bool
}

class SCPCameraView: UIView {
    
    @IBOutlet var cameraPreview: UIView!
    weak var cameraViewDelegate: SCPCollectionDelegate? = nil
    var cameraManager: CameraManager?
    var busy: Bool = false
    
    static func instance() -> SCPCameraView {
        return UINib(nibName: "SCPCameraView", bundle: NSBundle(forClass: self.classForCoder())).instantiateWithOwner(self, options: nil)[0] as! SCPCameraView
    }
    
    func initialize() {
        cameraManager = CameraManager()
        cameraManager!.cameraOutputMode = .StillImage
        cameraManager!.writeFilesToPhoneLibrary = false
        cameraManager!.addPreviewLayerToView(cameraPreview)
    }
    @IBAction func takePhotoBtnPressed(sender: UIButton) {
        if self.busy == false {
            self.busy = true
            self.cameraManager!.capturePictureWithCompletition({ (image, error) -> Void in
                self.capturePictureCompletion(image, error: error)
                self.busy = false
            })
        }
    }
    
    func capturePictureCompletion(image: UIImage?, error: NSError?) {
        if image != nil {
            self.cameraViewDelegate?.mediaFilePicked(image!)
        }
    }
}

