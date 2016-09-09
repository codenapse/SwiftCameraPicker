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
import CocoaLumberjack


public final class SCPViewController: UIViewController, SCPCollectionDelegate , SCPMediaSelectedLabelUpdateDelegate {
    
    enum CameraPickerModes {
        case Camera
        case Gallery
    }
    
    public var mediaFilesFromSession: [UIImage] = []
    public var mediaFilesFromSessionz: [Dictionary<String, UIImage?>] = []
    public lazy var delegate: SCPViewControllerCaptureDelegate? = nil
    typealias WriteMediaToPathClosure = (fileName: String, fileType: Int) -> String
    var writeMediaToPath: WriteMediaToPathClosure?
    //
    // header ui part
    @IBOutlet var headerView: UIView!
    @IBOutlet var headerCancelButton: UIButton!
    @IBOutlet var headerDoneButton: UIButton!
    //
    // mode menu ui part 
    @IBOutlet var menuView: UIView!
    var cameraModeButton: UIButton!
    @IBOutlet var galleryModeButton: UIButton!
    //
    // preview container ui part
    @IBOutlet var previewContainerView: UIView!
    lazy var cameraView = SCPCameraView.instance()
    lazy var galleryView = SCPGalleryView.instance()
    //
    // collection ui part
    @IBOutlet var mediaSelectedCounterView: UIView!
    @IBOutlet var mediaSelectedCounterLabel: UILabel!
    var collectionViewContainer: UIView!
    lazy var collectionView = SCPCollectionView.instance()
    //
    // private var's
    private var currentCameraPickerMode: CameraPickerModes = CameraPickerModes.Camera
    //
    // MARK:- IBAction methods
    //
    @IBAction func galleryModeBtnPressed(sender: UIButton) {
        DDLogDebug("[SCPViewController] -> galleryModeBtnPressed()")
        self.changeCameraPickerMode(CameraPickerModes.Gallery)
    }
    //
    //
    @IBAction func cameraModeBtnPressed(sender: UIButton) {
        DDLogDebug("[SCPViewController] -> cameraModeBtnPressed()")
        self.changeCameraPickerMode(CameraPickerModes.Camera)
    }
    //
    //
    @IBAction func headerCancelButtonPressed(sender: UIButton) {
        DDLogDebug("[SCPViewController] -> headerCancelButtonPressed()")
        self.dismissViewControllerAnimated(false, completion: nil)
    }
    //
    //
    @IBAction func headerDoneButtonPressed(sender: AnyObject) {
        let mediaFiles = self.collectionView.getMediaFilesFromSession()
        var videoFiles: [String] = []
        for media in mediaFiles {
            if media!.deleteToggle == false {
                if media!.mediaType == SCPMediaFile.MediaTypes["video"] {
                    DDLogDebug("[headerDoneButtonPressed] -> video file found")
                    videoFiles.append(media!.mediaPath)
                } else {
                    if media!.phAsset != nil {
//                        DDLogDebug("headerDoneButtonPressed() -> phasset != nil")
                        self.mediaFilesFromSession.append(media!.getImageFromPHAsset())
                    } else if media!.mediaPath != nil {
                        self.mediaFilesFromSession.append(UIImage(contentsOfFile: media!.mediaPath)!)
                    } else {
//                        DDLogDebug("headerDoneButtonPressed() -> phasset == nil")
                        self.mediaFilesFromSession.append(media!.image!)
                    }
                }
            } else {
                if media!.mediaPath != nil {
                    DDLogDebug("removeItemAtPath: \(media!.mediaPath!)")
                    let fileManager = NSFileManager.defaultManager()
                    do {
                        try fileManager.removeItemAtPath(media!.mediaPath)
                    }
                    catch _ as NSError {
                        
                    }
                }
            }
        }
        if self.delegate == nil {
            print("self.delegate == nil")
            return
        }
        self.delegate!.capturedVideoFilesFromSession(videoFiles)
        self.delegate!.capturedMediaFilesFromSession(self.mediaFilesFromSession)
        
        self.dismissViewControllerAnimated(false, completion: nil)
        if self.collectionView.mediaFiles != nil {
            for file in self.collectionView.mediaFiles {
                file?.cleanup()
            }
        }
        self.collectionView.mediaFiles = []
        self.mediaFilesFromSession = []
        self.delegate = nil
    }
    //
    // MARK:- Public methods
    //
    
    public func configWriteMediaToPath(closure: (fileName: String, fileType: Int ) -> String) {
        self.writeMediaToPath = closure as! WriteMediaToPathClosure
    }
    
    //
    // MARK:- Private methods
    //
    private func changeCameraPickerMode(mode: CameraPickerModes) {
        if case .Camera = mode {
            if self.currentCameraPickerMode == mode {
                DDLogDebug("[SCPViewController] -> changeCameraPickerMode() -> mode already set to .Camera")
                return
            }
            self.changeToCameraMode()
        } else if case .Gallery = mode {
            if self.currentCameraPickerMode == mode {
                DDLogDebug("[SCPViewController] -> changeCameraPickerMode() -> mode already set to .Gallery")
                return
            }
            self.changeToGalleryMode()
        }
        self.currentCameraPickerMode = mode
    }
    //
    //
    private func changeToCameraMode() {
        if let subview = self.previewContainerView.subviews.first {
            subview.removeFromSuperview()
        }
        self.previewContainerView.addSubview(self.cameraView)
        self.cameraView.bindSubViewToSuperview()
        
        self.galleryModeButton.backgroundColor = UIColor.fromHex("#ffffff")
        self.galleryModeButton.setTitleColor(UIColor.darkGrayColor(), forState: .Normal)
        
        self.cameraModeButton.backgroundColor = UIColor.fromHex("#34AB6E")
        self.cameraModeButton.setTitleColor(UIColor.fromHex("#ffffff"), forState: .Normal)
    }
    //
    //
    private func changeToGalleryMode() {
        if let subview = self.previewContainerView.subviews.first {
            subview.removeFromSuperview()
        }

        self.galleryView.initialize()
        self.previewContainerView.addSubview(self.galleryView)
        self.galleryView.bindSubViewToSuperview()
        
        self.cameraModeButton.backgroundColor = UIColor.fromHex("#ffffff")
        self.cameraModeButton.setTitleColor(UIColor.darkGrayColor(), forState: .Normal)
        
        self.galleryModeButton.backgroundColor = UIColor.fromHex("#34AB6E")
        self.galleryModeButton.setTitleColor(UIColor.fromHex("#ffffff"), forState: .Normal)
    }
    //
    //
    private func configureTheme() {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.headerView.backgroundColor = UIColor.fromHex("#dddddd")
            self.menuView.backgroundColor = UIColor.fromHex("#ffffff")
            self.previewContainerView.backgroundColor = UIColor.fromHex("#ffffff")
            self.collectionView.backgroundColor = UIColor.fromHex("#ffffff")
            self.cameraModeButton.backgroundColor = UIColor.fromHex("#34AB6E")
            self.cameraModeButton.setTitleColor(UIColor.fromHex("#ffffff"), forState: .Normal)
            self.mediaSelectedCounterView.backgroundColor = UIColor.fromHex("#dddddd")
            self.mediaSelectedCounterView.layer.cornerRadius = 8
            self.mediaSelectedCounterView.layer.borderColor = UIColor.fromHex("#eeeeee").CGColor
            self.mediaSelectedCounterView.layer.borderWidth = 1
        })
    }
    //
    // MARK:- Override methods
    //
    override public func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    //
    //
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.configureTheme()
        self.collectionView.mediaSelectedLabelUpdateDelegate = self
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.cameraModeButton = self.view.viewWithTag(2) as! UIButton
            self.cameraModeButton.layer.cornerRadius = 8
            self.galleryModeButton.layer.cornerRadius = 8
            
            self.cameraView.initialize()
            self.cameraView.cameraViewDelegate = self
            self.galleryView.delegate = self
            
            
            self.previewContainerView.addSubview(self.cameraView)
            self.cameraView.bindSubViewToSuperview()
            self.collectionViewContainer = self.view.viewWithTag(10)! as UIView
            self.collectionView.initialize()
            self.collectionViewContainer.addSubview(self.collectionView)
            self.collectionView.bindSubViewToSuperview()
            self.updateMediaSelectedLabel()
            self.view.layoutIfNeeded()
        })
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
        // set log output to TTY = Xcode console
        DDLog.addLogger(DDTTYLogger.sharedInstance())
        
        DDLogDebug("[SCPViewController] -> loadView()")
        if let view = UINib(nibName: "SCPViewController",
            bundle: NSBundle(forClass: self.classForCoder))
            .instantiateWithOwner(self, options: nil).first as? UIView { self.view = view }
    }
    //
    // MARK: - SCPCameraViewDelegate
    //
    func mediaFilePicked(image: UIImage) {
        DDLogDebug("[SCPViewController] -> mediaFilePicked()")
        let imageName = NSUUID().UUIDString
        let path = self.writeMediaToPath!(fileName: imageName, fileType: 1).stringByAppendingString(imageName).stringByAppendingString(".jpg")
        let imageData:NSData = UIImageJPEGRepresentation(image, 0.85)!
        imageData.writeToFile(path, atomically: true)
        self.collectionView.addMediaFileToCollection(nil, phAsset: nil, path: path)
        self.updateMediaSelectedLabel()
    }
    
    func mediaFileSelected(image: UIImage, phAsset: PHAsset) {
        DDLogDebug("[SCPViewController] -> mediaFileSelected()")
        self.collectionView.addMediaFileToCollection(image, phAsset: phAsset)
        self.updateMediaSelectedLabel()
    }
    
    func mediaFileRecorded(videoUrl: NSURL?, avAsset: AVAsset? = nil) {
//        DDLogDebug("[SCPViewController] -> mediaFileRecorded() -> \(videoUrl)")
        self.collectionView.addMediaFileToCollection(nil, phAsset: nil, videoUrl: videoUrl, avAsset: avAsset)
        self.updateMediaSelectedLabel()
    }
    
    func getVideoFilePath() -> String {
        let fileName = NSUUID().UUIDString
        let path = self.writeMediaToPath!(fileName: fileName, fileType: 2).stringByAppendingString(fileName).stringByAppendingString(".mp4")
        return path
    }
    
    func mediaSelectedLimitReached() -> Bool {
        if self.collectionView.getMediaSelectedCount() < self.collectionView.mediaSelectedLimit {
            return false
        }
        return true
    }
    //
    //
    func updateMediaSelectedLabel() {
        self.mediaSelectedCounterLabel.text = String(self.collectionView.getMediaSelectedCount()).stringByAppendingString(" / \(self.collectionView.mediaSelectedLimit)")
    }
}

public protocol SCPViewControllerCaptureDelegate: class {
    func capturedMediaFilesFromSession(mediaFiles: [UIImage])
    func capturedVideoFilesFromSession(videoFiles: [String])
}

extension UIView {
    func bindSubViewToSuperview() {
        guard let superview = self.superview else {
            DDLogDebug("Error! `superview` was nil – call `addSubview(view: UIView)` before calling `bindFrameToSuperviewBounds()` to fix this.")
            return
        }
        self.translatesAutoresizingMaskIntoConstraints = false
        superview.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[subview]-0-|", options: .DirectionLeadingToTrailing, metrics: nil, views: ["subview": self]))
        superview.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[subview]-0-|", options: .DirectionLeadingToTrailing, metrics: nil, views: ["subview": self]))
    }
}

extension UIColor {
    static func fromHex (hex: String) -> UIColor {
        var cString:String = hex.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet() as NSCharacterSet).uppercaseString
        
        if (cString.hasPrefix("#")) {
            cString = cString.substringFromIndex(cString.startIndex.advancedBy(1))
        }
        
        if ((cString.characters.count) != 6) {
            return UIColor.grayColor()
        }
        
        var rgbValue:UInt32 = 0
        NSScanner(string: cString).scanHexInt(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}