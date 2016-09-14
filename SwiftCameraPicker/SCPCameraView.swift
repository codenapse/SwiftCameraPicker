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
    func mediaFilePicked(image: UIImage)
    func mediaFileSelected(image: UIImage, phAsset: PHAsset)
    func mediaFileRecorded(videoUrl: NSURL?, avAsset: AVAsset?)
    func mediaSelectedLimitReached() -> Bool
    func getVideoFilePath(inspectionId: String) -> String
}

class SCPCameraView: UIView {
    
    @IBOutlet var videoLengthCountDownLabel: UILabel!
    @IBOutlet var recordingMode: UIView!
    @IBOutlet var cameraPreview: UIView!
    @IBOutlet var takePictureBtn: UIButton!
    @IBOutlet var videoToggleSwitch: UISwitch!
    weak var cameraViewDelegate: SCPCollectionDelegate? = nil
    var cameraManagerStillImage: CameraManager?
    var cameraManagerVideoOnly: CameraManager?
    var busy: Bool = false
    var videoLength = 10
    var videoLengthBlock: [dispatch_block_t] = []
    var stopVideoBlock: dispatch_block_t?
    public var inspectionId: String? = nil
    let cameraModes: Dictionary<String, CameraOutputMode> = [
        "Photo": .StillImage,
        "Video": .VideoOnly
    ]
    var cameraMode: CameraOutputMode? = nil//.StillImage
    
    
    static func instance() -> SCPCameraView {
        var view = UINib(nibName: "SCPCameraView", bundle: NSBundle(forClass: self.classForCoder())).instantiateWithOwner(self, options: nil)[0] as! SCPCameraView
        view.recordingMode.layer.cornerRadius = 6.0
        return view
    }
    
    func initialize(mode: String = "Photo") {
//        DDLogDebug("init with mode \(mode)")
        self.takePictureBtn.enabled = false
        self.videoToggleSwitch.enabled = false
        self.busy = true
        if self.cameraModes[mode] != nil {
            if mode == "Photo" {
                self.cameraManagerStillImage = nil
                self.cameraMode = self.cameraModes["Photo"]!
                var manager = CameraManager()
                manager.cameraOutputMode = self.cameraModes["Photo"]!
                manager.writeFilesToPhoneLibrary = false
                self.cameraManagerStillImage = manager
                self.cameraManagerStillImage!.addPreviewLayerToView(cameraPreview)
            } else {
                self.cameraManagerVideoOnly = nil
                self.cameraMode = self.cameraModes["Video"]!
                var manager = CameraManager()
                manager.cameraOutputMode = self.cameraModes["Video"]!
                manager.writeFilesToPhoneLibrary = false
                self.cameraManagerVideoOnly = manager
                self.cameraManagerVideoOnly!.addPreviewLayerToView(cameraPreview)
            }
            if self.cameraMode == self.cameraModes["Video"]! {
                self.recordingMode.hidden = false
                self.videoLengthCountDownLabel.text = String(self.videoLength)
            } else {
                self.recordingMode.hidden = true
            }
            
        } else {
            self.cameraMode = self.cameraModes["Photo"]!
            var manager = CameraManager()
            manager.cameraOutputMode = self.cameraModes["Photo"]!
            manager.writeFilesToPhoneLibrary = false
            self.cameraManagerStillImage = manager
            self.cameraManagerStillImage!.addPreviewLayerToView(cameraPreview)
        }
        self.busy = false
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.7 * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            self.takePictureBtn.enabled = true
            self.videoToggleSwitch.enabled = true
        }
    }
    @IBAction func takePhotoBtnPressed(sender: AnyObject) {
        if self.busy == false {
            self.busy = true
            
            if self.cameraMode == self.cameraModes["Photo"] {
                DDLogDebug("[SwiftCameraPicker][SCPCameraView] -> capture still image")
                self.cameraManagerStillImage!.capturePictureWithCompletition({ (image, error) -> Void in
                    if image != nil {
                        let squared = image//MediaFile.cropToSquare(image!)
                        self.capturePictureCompletion(squared, error: error)
                        self.busy = false
                    }
                })
            } else if self.cameraMode == self.cameraModes["Video"] {
                DDLogDebug("[SwiftCameraPicker][SCPCameraView] -> start recording video")
                self.cameraManagerVideoOnly!.startRecordingVideo()
                self.videoToggleSwitch.enabled = false
                // update ui labels
                DDLogDebug("[SwiftCameraPicker][SCPCameraView] -> video length: \(0)")
                self.videoLengthBlock = []
                for second in 1...self.videoLength {
                     var block = SCPMediaFile.delay(second) {
                        if self.busy == true {
                            DDLogDebug("[SwiftCameraPicker][SCPCameraView] -> video length: \(second)")
                            self.videoLengthCountDownLabel.text = String(self.videoLength - second)
                        }
                    }
                    self.videoLengthBlock.append(block)
                }
                
                // stop recording
                self.stopVideoBlock = nil
                self.stopVideoBlock = SCPMediaFile.delay(self.videoLength) {
                    if self.busy == true {
                        self.stopAndSaveVideo()
                    }
                }
            }
        } else if self.cameraMode == self.cameraModes["Video"] {
            self.stopAndSaveVideo()
        }
    }
    
    @IBAction func toggleVideoMode(sender: UISwitch) {
        if sender.on == true {
            self.initialize("Video")
        } else {
            self.initialize("Photo")
        }
    }
    func capturePictureCompletion(image: UIImage?, error: NSError?) {
        if image != nil {
            self.cameraViewDelegate?.mediaFilePicked(image!)
        }
    }
    
    func captureVideoCompletion(videoUrl: NSURL?, error: NSError?) {
        if error != nil {
            return
        }
        self.cameraViewDelegate?.mediaFileRecorded(videoUrl!, avAsset: nil)
        self.videoLengthCountDownLabel.text = String(self.videoLength)
    }
    
    func stopAndSaveVideo() {
        DDLogDebug("[SwiftCameraPicker][SCPCameraView] -> stop recording video")
        for block in self.videoLengthBlock {
            dispatch_block_cancel(block)
        }
        dispatch_block_cancel(self.stopVideoBlock!)
        self.stopVideoBlock = nil
        self.videoLengthBlock = []
        self.busy = false
        self.cameraManagerVideoOnly!.stopRecordingVideo({ (videoURL, error) -> Void in
            if error == nil {
                let path = NSURL(fileURLWithPath: (self.cameraViewDelegate?.getVideoFilePath(self.inspectionId!))!)
                do {
                    try NSFileManager.defaultManager().copyItemAtURL(videoURL!, toURL: path)
                    DDLogDebug("[SwiftCameraPicker][SCPCameraView] -> video file saved at: \(path)")
                    self.captureVideoCompletion(path, error: error)
                    self.videoToggleSwitch.enabled = true
                    
                } catch let err as NSError {
                    DDLogError("[SwiftCameraPicker][SCPCameraView] -> failed to move video file to path: \(path) - err: \(err)")
                }
            }
        })
    }
    
}







