//
//  SCPGalleryView.swift
//  SwiftCameraPicker
//
//  Created by Alin Paulesc on 01/08/16.
//  Copyright © 2016 codenapse. All rights reserved.
//

import UIKit
import Photos
import CocoaLumberjack

class SCPGalleryView: UIView, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet var collectionView: UICollectionView!
    private var cellReuseIdentifier = "SCPGalleryViewCell"
    private var mediaAssets: [SCPAsset] = []
    public lazy var inspectionId: String? = nil
    var delegate: SCPCollectionDelegate!
    
    
    static func instance() -> SCPGalleryView {
        return UINib(nibName: "SCPGalleryView", bundle: NSBundle(forClass: self.classForCoder())).instantiateWithOwner(self, options: nil).first as! SCPGalleryView
    }
    
    func initialize() {
        if self.mediaAssets.count == 0 {
            self.initMediaFiles()
        }
        let bundle = NSBundle(forClass: self.dynamicType)
        self.collectionView.registerNib(UINib(nibName: "SCPGalleryViewCell", bundle: bundle), forCellWithReuseIdentifier: self.cellReuseIdentifier)
    }
    func initMediaFiles() {
        var assets: [PHAsset] = []
        let options = PHFetchOptions()
        options.sortDescriptors = [
            NSSortDescriptor(key: "creationDate", ascending: true)
        ]
        var tempVideos: [SCPAsset] = []
        let videos = PHAsset.fetchAssetsWithMediaType(.Video, options: options)
        videos.enumerateObjectsUsingBlock { (object, _, _) in
            if let asset = object as? PHAsset {
                SCPAsset.imageManager.requestAVAssetForVideo(asset, options: nil, resultHandler: {(avAsset: AVAsset?, audioMix: AVAudioMix?, info: [NSObject : AnyObject]?) -> Void in
                    var scpAsset = SCPAsset(initWithPHAsset: asset, videoFlag: true)
                    scpAsset.avAsset = avAsset!
                    scpAsset.inspectionUUID = self.inspectionId!
                    scpAsset.mediaType = SCPAsset.MediaTypes["video"]!
                    tempVideos.append(scpAsset)
                })
            }
        }
        var results = PHAsset.fetchAssetsWithMediaType(.Image, options: options)
        results.enumerateObjectsUsingBlock { (object, _, _) in
            if let asset = object as? PHAsset {
                assets.append(asset)
                
            }
        }
        
        SCPAsset.imageManager.startCachingImagesForAssets(assets,
                                                              targetSize: CGSize(width: 110.0, height: 147.0),
                                                              contentMode: .AspectFill,
                                                              options: nil
        )
        for asset in assets {
            var scpAsset = SCPAsset(initWithPHAsset: asset)
            scpAsset.inspectionUUID = self.inspectionId!
            self.mediaAssets.append(scpAsset)
        }
        for video in tempVideos {
            self.mediaAssets.append(video)
        }
    }
    //
    // MARK: - UICollectionViewDataSource
    //
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        DDLogDebug("Media files count = \(self.mediaAssets.count)")
        return self.mediaAssets.count
    }
    
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("SCPGalleryViewCell", forIndexPath: indexPath) as! SCPGalleryViewCell
        let mediaFile = self.mediaAssets[indexPath.row]
        cell.imageView?.image = mediaFile.getImageFromPHAsset(CGSize(width: 110.0, height: 147.0))
        cell.mediaFile = mediaFile
        cell.setup()
        return cell
    }
    
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    //
    // MARK: - UICollectionViewDelegate
    //
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        DDLogDebug("[SCPGalleryView] -> collectionView() -> media file tapped")
        let cell : SCPGalleryViewCell = collectionView.cellForItemAtIndexPath(indexPath) as! SCPGalleryViewCell
        if self.delegate.mediaSelectedLimitReached() == true {
            return
        }
        let asset = self.mediaAssets[indexPath.row]
        if asset.selected == true {
            return
        }
        var scpAsset = self.mediaAssets[indexPath.row]
        self.delegate.mediaFileFromGallery(scpAsset)
        cell.toggle()
    }
    
    func checkPhotoAuth() -> Bool {
        var accessGranted = false
        PHPhotoLibrary.requestAuthorization { (status) -> Void in
            switch status {
            case .Authorized:
                DDLogDebug("[SCPGalleryView] -> checkPhotoAuth() - user Authorized access to PhotoLibrary")
                accessGranted = true
            case .Restricted, .Denied:
                DDLogError("[SCPGalleryView] -> checkPhotoAuth() - user Denied access to PhotoLibrary")
            default:
                break
            }
        }
        return accessGranted
    }
}


