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
        case camera
        case gallery
    }
    
    public var mediaFilesFromSession: [String] = []
    public var mediaFilesFromSessionz: [Dictionary<String, UIImage?>] = []
    public lazy var inspectionId: String? = nil
    public lazy var delegate: SCPViewControllerCaptureDelegate? = nil
    typealias WriteMediaToPathClosure = (_ fileName: String, _ fileType: Int, _ inspectionId: String) -> String
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
    fileprivate var currentCameraPickerMode: CameraPickerModes = CameraPickerModes.camera
    //
    // MARK:- IBAction methods
    //
    @IBAction func galleryModeBtnPressed(_ sender: UIButton) {
        DDLogDebug("[SCPViewController] -> galleryModeBtnPressed()")
        self.changeCameraPickerMode(CameraPickerModes.gallery)
    }
    
    
    @IBAction func cameraModeBtnPressed(_ sender: UIButton) {
        DDLogDebug("[SCPViewController] -> cameraModeBtnPressed()")
        self.changeCameraPickerMode(CameraPickerModes.camera)
    }
    
    
    @IBAction func headerCancelButtonPressed(_ sender: UIButton) {
        DDLogDebug("[SCPViewController] -> headerCancelButtonPressed()")
        let mediaFiles = self.collectionView.getMediaFilesFromSession()
        for media in mediaFiles {
            if media.mediaPath != nil {
                if media.mediaType == SCPAsset.MediaTypes["video"] {
                    media.mediaPath = media.mediaPath.replacingOccurrences(of: "file:///", with: "/")
                }
                self.removeMediaFile(media)
            }
        }
        self.dismiss(animated: false, completion: nil)
    }
    
    
    @IBAction func headerDoneButtonPressed(_ sender: AnyObject) {
        let mediaFiles = self.collectionView.getMediaFilesFromSession()
        var videoFiles: [String] = []
        for media in mediaFiles {
            if media.deleteToggle == false {
                if media.mediaType == SCPAsset.MediaTypes["video"] {
                    DDLogDebug("[headerDoneButtonPressed] -> video file found")
                    videoFiles.append(media.mediaPath)
                } else {
                    self.mediaFilesFromSession.append(media.fileName!)
                }
            } else {
                if media.mediaPath != nil {
                    if media.mediaType == SCPAsset.MediaTypes["video"] {
                        media.mediaPath = media.mediaPath.replacingOccurrences(of: "file:///", with: "/")
                    }
                    self.removeMediaFile(media)
                }
            }
        }
        if self.delegate == nil {
            return
        }
        self.delegate!.capturedVideoFilesFromSession(videoFiles)
        self.delegate!.capturedMediaFilesFromSession(self.mediaFilesFromSession)
        
        self.dismiss(animated: false, completion: nil)
//        if self.collectionView.mediaFiles != nil {
//            for file in self.collectionView.mediaFiles {
//                file?.cleanup()
//            }
//        }
        self.collectionView.mediaFiles = []
        self.mediaFilesFromSession = []
        self.delegate = nil
    }
    //
    // MARK:- Public methods
    //
    
    public func configWriteMediaToPath(_ closure: @escaping (_ fileName: String, _ fileType: Int, _ inspectionId: String) -> String) {
        self.writeMediaToPath = closure 
    }
    
    public func setInspectionUuid(_ inspectionId: String) {
        self.inspectionId = inspectionId
    }
    
    //
    // MARK:- Private methods
    //
    fileprivate func changeCameraPickerMode(_ mode: CameraPickerModes) {
        if case .camera = mode {
            if self.currentCameraPickerMode == mode {
                DDLogDebug("[SCPViewController] -> changeCameraPickerMode() -> mode already set to .Camera")
                return
            }
            self.changeToCameraMode()
        } else if case .gallery = mode {
            if self.currentCameraPickerMode == mode {
                DDLogDebug("[SCPViewController] -> changeCameraPickerMode() -> mode already set to .Gallery")
                return
            }
            self.changeToGalleryMode()
        }
        self.currentCameraPickerMode = mode
    }
    
    
    fileprivate func changeToCameraMode() {
        if let subview = self.previewContainerView.subviews.first {
            subview.removeFromSuperview()
        }
        self.previewContainerView.addSubview(self.cameraView)
        self.cameraView.bindSubViewToSuperview()
        
        self.galleryModeButton.backgroundColor = UIColor.fromHex("#ffffff")
        self.galleryModeButton.setTitleColor(UIColor.darkGray, for: UIControlState())
        
        self.cameraModeButton.backgroundColor = UIColor.fromHex("#34AB6E")
        self.cameraModeButton.setTitleColor(UIColor.fromHex("#ffffff"), for: UIControlState())
    }
    
    
    fileprivate func changeToGalleryMode() {
        if let subview = self.previewContainerView.subviews.first {
            subview.removeFromSuperview()
        }

        self.galleryView.initialize()
        self.previewContainerView.addSubview(self.galleryView)
        self.galleryView.bindSubViewToSuperview()
        
        self.cameraModeButton.backgroundColor = UIColor.fromHex("#ffffff")
        self.cameraModeButton.setTitleColor(UIColor.darkGray, for: UIControlState())
        
        self.galleryModeButton.backgroundColor = UIColor.fromHex("#34AB6E")
        self.galleryModeButton.setTitleColor(UIColor.fromHex("#ffffff"), for: UIControlState())
    }
    
    
    fileprivate func configureTheme() {
        DispatchQueue.main.async(execute: { () -> Void in
            self.headerView.backgroundColor = UIColor.fromHex("#dddddd")
            self.menuView.backgroundColor = UIColor.fromHex("#ffffff")
            self.previewContainerView.backgroundColor = UIColor.fromHex("#ffffff")
            self.collectionView.backgroundColor = UIColor.fromHex("#ffffff")
            self.cameraModeButton.backgroundColor = UIColor.fromHex("#34AB6E")
            self.cameraModeButton.setTitleColor(UIColor.fromHex("#ffffff"), for: UIControlState())
            self.mediaSelectedCounterView.backgroundColor = UIColor.fromHex("#dddddd")
            self.mediaSelectedCounterView.layer.cornerRadius = 8
            self.mediaSelectedCounterView.layer.borderColor = UIColor.fromHex("#eeeeee").cgColor
            self.mediaSelectedCounterView.layer.borderWidth = 1
        })
    }
    //
    // MARK:- Override methods
    //
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        let value = UIInterfaceOrientation.Portrait.rawValue
//        UIDevice.currentDevice().setValue(value, forKey: "orientation")
    }
    

//    override public func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
//        return UIInterfaceOrientationMask.Portrait
//    }
//    
//    
//    override public func shouldAutorotate() -> Bool {
//        return true
//    }
    override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        setVideoOrientation()
    }
    
    private func setVideoOrientation() {
        let value = UIDevice.current.orientation
        let orientation = "orientation"
        
        switch value {
        case .portraitUpsideDown:
            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: orientation)
        default: break
        }
    }
    
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.configureTheme()
        self.collectionView.mediaSelectedLabelUpdateDelegate = self
        self.cameraView.cameraViewDelegate = self
        self.galleryView.delegate = self
        DispatchQueue.main.async(execute: { () -> Void in
            self.cameraModeButton = self.view.viewWithTag(2) as! UIButton
            self.cameraModeButton.layer.cornerRadius = 8
            self.galleryModeButton.layer.cornerRadius = 8
            self.cameraView.initialize()
            self.cameraView.inspectionId = self.inspectionId
            self.galleryView.inspectionId = self.inspectionId
            self.galleryView.checkPhotoAuth()
            self.previewContainerView.addSubview(self.cameraView)
            self.cameraView.bindSubViewToSuperview()
            self.collectionViewContainer = self.view.viewWithTag(10)! as UIView
            self.collectionView.initialize()
            self.collectionViewContainer.addSubview(self.collectionView)
            self.collectionView.bindSubViewToSuperview()
            self.updateMediaSelectedLabel()
            self.view.layoutIfNeeded()
        })
        // MARK:- mock for testing new SCPAsset
        
    }
    
    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override public func loadView() {
        // set log output to TTY = Xcode console
        DDLog.add(DDTTYLogger.sharedInstance)
        if let view = UINib(nibName: "SCPViewController",
            bundle: Bundle(for: self.classForCoder))
            .instantiate(withOwner: self, options: nil).first as? UIView { self.view = view }
    }
    //
    // MARK: - SCPCameraViewDelegate
    //
    func mediaFilePicked(_ image: UIImage) {
        DDLogDebug("[SCPViewController] -> .stillImage captured")
        let asset = SCPAsset(initWithImage: image)
        asset.inspectionUUID = self.inspectionId!
        asset.generateFileName
        asset.writeFileToPath()
        self.collectionView.addMediaFileToCollection(nil, phAsset: nil, scpAsset: asset)
    }
    
    func mediaFileSelected(_ image: UIImage, phAsset: PHAsset) {
        DDLogDebug("[SCPViewController] -> mediaFileSelected() \(image.size.width)x\(image.size.height)")
        self.collectionView.addMediaFileToCollection(image, phAsset: phAsset)
    }
    
    func mediaFileRecorded(_ videoUrl: URL) {
        let asset = SCPAsset(initWithTempVideoPath: videoUrl)
        asset.inspectionUUID = self.inspectionId!
        asset.generateFileName
        asset.writeFileToPath()
        self.collectionView.addMediaFileToCollection(nil, phAsset: nil, scpAsset: asset)
    }
    
    func mediaFileFromGallery(_ asset: SCPAsset) {
        asset.generateFileName
        asset.inspectionUUID = self.inspectionId!
        if asset.mediaType == SCPAsset.MediaTypes["photo"] {
            DDLogDebug("mediaFileFromGallery photo")
            asset.writeFileToPath()
        } else {
            DDLogDebug("mediaFileFromGallery video")
            asset.exportVideoFromPhotoLib()
        }
        self.collectionView.addMediaFileToCollection(nil, phAsset: nil, scpAsset: asset)
    }
    
    func getVideoFilePath(_ inspectionId: String) -> String {
        let fileName = UUID().uuidString
        let path = (self.writeMediaToPath!(fileName, 2, inspectionId) + fileName) + "_original.mp4"
        return path
    }
    
    func mediaSelectedLimitReached() -> Bool {
        if self.collectionView.getMediaSelectedCount() < self.collectionView.mediaSelectedLimit {
            return false
        }
        return true
    }
    
    func toggleHeaderButtons() {
        if self.headerDoneButton.isEnabled == true {
            self.headerDoneButton.isEnabled = false
            self.headerCancelButton.isEnabled = false
        } else {
            self.headerDoneButton.isEnabled = true
            self.headerCancelButton.isEnabled = true
        }
    }
    
    func updateMediaSelectedLabel() {
        self.mediaSelectedCounterLabel.text = String(self.collectionView.getMediaSelectedCount()) + " / \(self.collectionView.mediaSelectedLimit)"
    }
    
    func removeMediaFile(_ mediaFile: SCPAsset) {
        if mediaFile.mediaType == SCPAsset.MediaTypes["video"] {
            // delete original
            self.deleteMediaFileAt(mediaFile.mediaPath!)
            let path = mediaFile.filePathNoExtension!
            // delete preview
            self.deleteMediaFileAt(path + "_preview.jpg")
            // delete thumb
            self.deleteMediaFileAt(path + "_thumb.jpg")
        } else {
            // delete original
            self.deleteMediaFileAt(mediaFile.mediaPath!)
            let path = mediaFile.filePathNoExtension!
            // delete thumb
            self.deleteMediaFileAt(path + "_thumb.jpg")
        }
    }
    
    fileprivate func deleteMediaFileAt(_ path: String) {
        var block = SCPAsset.delay(delay: 2) {
            let fileManager = FileManager.default
            do {
                try fileManager.removeItem(atPath: path)
//                DDLogDebug("[SCPViewController][deleteMediaFileAt] media file deleted: \(path)")
            }
            catch let err as NSError {
//                DDLogWarn("[SCPViewController][deleteMediaFileAt] failed to delete media file: \(err.debugDescription)")
            }
        }
    }
}

public protocol SCPViewControllerCaptureDelegate: class {
    func capturedMediaFilesFromSession(_ mediaFiles: [String])
    func capturedVideoFilesFromSession(_ videoFiles: [String])
}

extension UIView {
    func bindSubViewToSuperview() {
        guard let superview = self.superview else {
            DDLogDebug("Error! `superview` was nil – call `addSubview(view: UIView)` before calling `bindFrameToSuperviewBounds()` to fix this.")
            return
        }
        self.translatesAutoresizingMaskIntoConstraints = false
        superview.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[subview]-0-|", options: NSLayoutFormatOptions(), metrics: nil, views: ["subview": self]))
        superview.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[subview]-0-|", options: NSLayoutFormatOptions(), metrics: nil, views: ["subview": self]))
    }
}

extension UIColor {
    static func fromHex (_ hex: String) -> UIColor {
        //var cString:String = hex.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet() as NSCharacterSet).uppercased()
        
        var cString:String = hex.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).uppercased()
        if (cString.hasPrefix("#")) {
            cString = cString.substring(from: cString.characters.index(cString.startIndex, offsetBy: 1))
        }
        
        if ((cString.characters.count) != 6) {
            return UIColor.gray
        }
        
        var rgbValue:UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}
