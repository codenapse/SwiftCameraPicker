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
import CocoaLumberjack


protocol SCPCollectionDelegate: class {
    func mediaFilePicked(_ image: UIImage)
    func mediaFileSelected(_ image: UIImage, phAsset: PHAsset)
    func mediaFileFromGallery(_ asset: SCPAsset)
    func mediaFileRecorded(_ videoUrl: URL)
    func mediaSelectedLimitReached() -> Bool
    func getVideoFilePath(_ inspectionId: String) -> String
    func toggleHeaderButtons()
}

class SCPCameraView: UIView {
    
    @IBOutlet var videoLengthCountDownLabel: UILabel!
    @IBOutlet var recordingMode: UIView!
    @IBOutlet var cameraPreview: UIView!
    @IBOutlet var takePictureBtn: UIButton!
    @IBOutlet var videoToggleSwitch: UISwitch!
    var cameraViewDelegate: SCPCollectionDelegate? = nil
    var cameraManagerStillImage: CameraManager?
    var cameraManagerVideoOnly: CameraManager?
    var busy: Bool = false
    var videoLength = 10
    var videoLengthBlock: [DispatchWorkItem] = []
    var stopVideoBlock: DispatchWorkItem?
    var inspectionId: String? = nil
    let cameraModes: Dictionary<String, CameraOutputMode> = [
        "photo": .stillImage,
        "video": .videoOnly
    ]
    var cameraMode: CameraOutputMode? = nil
    var tapGesture:UITapGestureRecognizer? = nil
    
    static func instance() -> SCPCameraView {
        let view = UINib(nibName: "SCPCameraView", bundle: Bundle(for: self.classForCoder())).instantiate(withOwner: self, options: nil)[0] as! SCPCameraView
        view.recordingMode.layer.cornerRadius = 6.0
        return view
    }
    
    
    func initialize(_ mode: String = "photo") {
        self.takePictureBtn.isEnabled = false
        self.videoToggleSwitch.isEnabled = false
        self.busy = true
        if self.cameraModes[mode] != nil {
            if mode == "photo" {
                self.reinitCameraManagerForStillImage()
            } else {
                self.reinitCameraManagerForVideo()
            }
        } else {
            self.reinitCameraManagerForStillImage()
        }
        if self.cameraMode == self.cameraModes["video"]! {
            self.recordingMode.isHidden = false
            self.videoLengthCountDownLabel.text = String(self.videoLength)
        } else {
            self.recordingMode.isHidden = true
        }
        self.busy = false
        let delayTime = DispatchTime.now() + Double(Int64(1.1 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            self.takePictureBtn.isEnabled = true
            self.videoToggleSwitch.isEnabled = true
        }
    }
    @IBAction func takePhotoBtnPressed(_ sender: AnyObject) {
        if self.busy == false {
            self.busy = true
            if self.cameraMode == self.cameraModes["photo"] {
                if self.cameraViewDelegate!.mediaSelectedLimitReached(){
                    DDLogDebug("[SwiftCameraPicker][SCPCameraView] -> media selected limit reached")
                    self.busy = false
                }
                else{
                    DDLogDebug("[SwiftCameraPicker][SCPCameraView] -> capture still image")
                    self.cameraManagerStillImage!.capturePictureWithCompletion({ (image, error) -> Void in
                        if image != nil {
                            let squared = image
                            self.capturePictureCompletion(squared, error: error)
                            self.busy = false
                        }
                    })
                }
                
            } else if self.cameraMode == self.cameraModes["video"] {
                if self.cameraViewDelegate!.mediaSelectedLimitReached(){
                    DDLogDebug("[SwiftCameraPicker][SCPCameraView] -> media selected limit reached")
                    self.busy = false
                }
                else{
                    DDLogDebug("[SwiftCameraPicker][SCPCameraView] -> start recording video")
                    self.cameraViewDelegate!.toggleHeaderButtons()
                    self.cameraManagerVideoOnly!.startRecordingVideo()
                    self.videoToggleSwitch.isEnabled = false
                    // update ui labels
                    DDLogDebug("[SwiftCameraPicker][SCPCameraView] -> video length: \(0)")
                    self.videoLengthBlock = []
                    for second in 1...self.videoLength {
                        let block = SCPAsset.delay(delay: Double(second)) {
                            if self.busy == true {
                                DDLogDebug("[SwiftCameraPicker][SCPCameraView] -> video length: \(second)")
                                self.videoLengthCountDownLabel.text = String(self.videoLength - second)
                            }
                        }
                        self.videoLengthBlock.append(block)
                    }
                    
                    // stop recording
                    self.stopVideoBlock = nil
                    self.stopVideoBlock = SCPAsset.delay(delay: Double(self.videoLength)) {
                        if self.busy == true {
                            self.stopAndSaveVideo()
                        }
                    }
                    
                }
            }// else if
        } else if self.cameraMode == self.cameraModes["video"] {
            self.stopAndSaveVideo()
        }
    }
    
    @IBAction func toggleVideoMode(_ sender: UISwitch) {
        if sender.isOn == true {
            self.initialize("video")
        } else {
            self.initialize("photo")
        }
    }
    func capturePictureCompletion(_ image: UIImage?, error: NSError?) {
        if image != nil {
            self.cameraViewDelegate?.mediaFilePicked(image!)
        }
    }
    
    func captureVideoCompletion(_ videoUrl: URL?, error: NSError?) {
        if error != nil {
            return
        }
        self.cameraViewDelegate?.mediaFileRecorded(videoUrl!)
        self.videoLengthCountDownLabel.text = String(self.videoLength)
    }
    
    func stopAndSaveVideo() {
        DDLogDebug("[SwiftCameraPicker][SCPCameraView] -> stop recording video")
        for block in self.videoLengthBlock {
            block.cancel()
        }
        self.stopVideoBlock?.cancel()
        self.stopVideoBlock = nil
        self.videoLengthBlock = []
        self.busy = false
        self.cameraViewDelegate?.toggleHeaderButtons()
        self.cameraManagerVideoOnly!.stopVideoRecording({ (videoURL, error) -> Void in
            if error == nil {
                self.cameraViewDelegate?.mediaFileRecorded(videoURL!)
            }
        })
        self.videoLengthCountDownLabel.text = String(self.videoLength)
        self.videoToggleSwitch.isEnabled = true
    }
    //
    // MARK:- Private methods
    //
    fileprivate func reinitCameraManagerForVideo() {
        self.cameraManagerStillImage = nil
        if self.tapGesture == nil {
            self.tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.takePhotoBtnPressed(_:)))
            self.recordingMode.addGestureRecognizer(self.tapGesture!)
        }
        self.cameraManagerVideoOnly = nil
        self.cameraMode = self.cameraModes["video"]!
        let manager = CameraManager()
        manager.cameraOutputMode = self.cameraModes["video"]!
        manager.writeFilesToPhoneLibrary = false
        self.cameraManagerVideoOnly = manager
        self.cameraManagerVideoOnly!.addPreviewLayerToView(cameraPreview)
    }
    
    
    fileprivate func reinitCameraManagerForStillImage() {
        self.cameraManagerVideoOnly = nil
        self.cameraManagerStillImage = nil
        self.cameraMode = self.cameraModes["photo"]!
        let manager = CameraManager()
        manager.cameraOutputMode = self.cameraModes["photo"]!
        manager.writeFilesToPhoneLibrary = false
        self.cameraManagerStillImage = manager
        self.cameraManagerStillImage!.addPreviewLayerToView(cameraPreview)
    }
}






