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
    private var mediaFiles: [SCPMediaFile] = []
    var delegate: SCPCameraViewDelegate!
    var cachingImageManager: PHCachingImageManager = PHCachingImageManager()
    let manager = PHImageManager.defaultManager()
    var assets: [PHAsset] = []
    
    
    
    static func instance() -> SCPGalleryView {
        return UINib(nibName: "SCPGalleryView", bundle: NSBundle(forClass: self.classForCoder())).instantiateWithOwner(self, options: nil).first as! SCPGalleryView
    }
    
    func initialize() {
        self.collectionView.registerNib(UINib(nibName: "SCPGalleryViewCell", bundle: nil), forCellWithReuseIdentifier: self.cellReuseIdentifier)
        self.initMediaFiles()
        self.layoutIfNeeded()

    }
    func initMediaFiles() {
        self.checkPhotoAuth()
        
        let options = PHFetchOptions()
        // options.predicate = NSPredicate(format: "favorite == YES")
        options.sortDescriptors = [
            NSSortDescriptor(key: "creationDate", ascending: true)
        ]
        
        let results = PHAsset.fetchAssetsWithMediaType(.Image, options: options)
        results.enumerateObjectsUsingBlock { (object, _, _) in
            if let asset = object as? PHAsset {
                self.assets.append(asset)
            }
        }
        
        self.cachingImageManager.startCachingImagesForAssets(assets,
                                                        targetSize: CGSize(width: 85.0, height: 100.0),
                                                        contentMode: .AspectFill,
                                                        options: nil
        )
    }
    
    
    
    
    //
    // MARK: - UICollectionViewDataSource
    //
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        DDLogDebug("assets.count = \(self.assets.count)")
        return self.assets.count
//        return self.mediaFiles.count
    }
    //
    //
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("SCPGalleryViewCell", forIndexPath: indexPath) as! SCPGalleryViewCell
        
        let manager = PHImageManager.defaultManager()
        let options = PHImageRequestOptions()
        options.resizeMode = PHImageRequestOptionsResizeMode.Exact
        options.deliveryMode = PHImageRequestOptionsDeliveryMode.Opportunistic
        
        if cell.tag != 0 {
            manager.cancelImageRequest(PHImageRequestID(cell.tag))
        }
        let asset = assets[indexPath.row]
        cell.tag = Int(manager.requestImageForAsset(asset,
            targetSize: CGSize(width: 110.0, height: 147.0),
            contentMode: .AspectFill,
            options: options) { (result, _) in
                cell.imageView?.image = result
            }
        )
        return cell
    }
    //
    //
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    //
    //    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
    //
    //    }
    //
    // MARK: - UICollectionViewDelegate
    //
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let cell : SCPGalleryViewCell = collectionView.cellForItemAtIndexPath(indexPath) as! SCPGalleryViewCell
        
        if cell.tag != 0 {
            manager.cancelImageRequest(PHImageRequestID(cell.tag))
        }
        let asset = assets[indexPath.row]
        
        manager.requestImageForAsset(asset,
                                     targetSize: PHImageManagerMaximumSize,
                                     contentMode: .AspectFit,
                                     options: nil) { (result, _) in
                                        self.delegate.cameraShotFinished(result!)
                                     }
        cell.toggle()
    }
    
    private func checkPhotoAuth() {
        
        PHPhotoLibrary.requestAuthorization { (status) -> Void in
            switch status {
            case .Authorized:
                DDLogDebug("[SCPGalleryView] -> checkPhotoAuth() - user Authorized access to PhotoLibrary")
//                if self.images != nil && self.images.count > 0 {
//
//                }
                
            case .Restricted, .Denied:
                DDLogError("[SCPGalleryView] -> checkPhotoAuth() - user Denied access to PhotoLibrary")
            default:
                break
            }
        }
    }
}


