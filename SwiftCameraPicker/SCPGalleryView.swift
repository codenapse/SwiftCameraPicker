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
    fileprivate var cellReuseIdentifier = "SCPGalleryViewCell"
    fileprivate var mediaAssets: [SCPAsset] = []
    internal lazy var inspectionId: String? = nil
    var delegate: SCPCollectionDelegate!
    
    
    static func instance() -> SCPGalleryView {
        return UINib(nibName: "SCPGalleryView", bundle: Bundle(for: self.classForCoder())).instantiate(withOwner: self, options: nil).first as! SCPGalleryView
    }
    
    func initialize() {
        if self.mediaAssets.count == 0 {
            self.initMediaFiles()
        }
        let bundle = Bundle(for: type(of: self))
        self.collectionView.register(UINib(nibName: "SCPGalleryViewCell", bundle: bundle), forCellWithReuseIdentifier: self.cellReuseIdentifier)
    }
    func initMediaFiles() {
        var assets: [PHAsset] = []
        let options = PHFetchOptions()
        options.sortDescriptors = [
            NSSortDescriptor(key: "creationDate", ascending: false)
        ]
	options.fetchLimit = 1000
/*	don't import videos, we can't limit to 10 seconds
 *        var tempVideos: [SCPAsset] = []
 *        let videos = PHAsset.fetchAssetsWithMediaType(.Video, options: options)
 *        videos.enumerateObjectsUsingBlock { (object, _, _) in
 *            if let asset = object as? PHAsset {
 *                SCPAsset.imageManager.requestAVAssetForVideo(asset, options: nil, resultHandler: {(avAsset: AVAsset?, audioMix: AVAudioMix?, info: [NSObject : AnyObject]?) -> Void in
 *                    let scpAsset = SCPAsset(initWithPHAsset: asset, videoFlag: true)
 *                    scpAsset.avAsset = avAsset!
 *                    scpAsset.inspectionUUID = self.inspectionId!
 *                    scpAsset.mediaType = SCPAsset.MediaTypes["video"]!
 *                    tempVideos.append(scpAsset)
 *                })
 *            }
 *        }
 */
        let results = PHAsset.fetchAssets(with: .image, options: options)
//        results.enumerateObjects { (object, _, _) in
//            if let asset = object as? PHAsset {
//                assets.append(asset)
//                
//            }
//        }
        results.enumerateObjects({ (object, _, _) in
            if let asset = object as? PHAsset {
                assets.append(asset)
                
            }
        })
        
        
        SCPAsset.imageManager.startCachingImages(for: assets,
                                                              targetSize: CGSize(width: 110.0, height: 147.0),
                                                              contentMode: .aspectFill,
                                                              options: nil
        )
        for asset in assets {
            let scpAsset = SCPAsset(initWithPHAsset: asset)
            scpAsset.inspectionUUID = self.inspectionId!
            self.mediaAssets.append(scpAsset)
        }
/*        for video in tempVideos {
 *            self.mediaAssets.append(video)
 *        }
 */
    }
    //
    // MARK: - UICollectionViewDataSource
    //
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        DDLogDebug("Media files count = \(self.mediaAssets.count)")
        return self.mediaAssets.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SCPGalleryViewCell", for: indexPath) as! SCPGalleryViewCell
        let mediaFile = self.mediaAssets[indexPath.row]
        cell.imageView?.image = mediaFile.getImageFromPHAsset(CGSize(width: 110.0, height: 147.0))
        cell.mediaFile = mediaFile
        cell.setup()
        return cell
    }
    
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    //
    // MARK: - UICollectionViewDelegate
    //
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        DDLogDebug("[SCPGalleryView] -> collectionView() -> media file tapped")
        let cell : SCPGalleryViewCell = collectionView.cellForItem(at: indexPath) as! SCPGalleryViewCell
        if self.delegate.mediaSelectedLimitReached() == true {
            return
        }
        let asset = self.mediaAssets[indexPath.row]
        if asset.selected == true {
            return
        }
        let scpAsset = self.mediaAssets[indexPath.row]
        self.delegate.mediaFileFromGallery(scpAsset)
        cell.toggle()
    }
    
    func checkPhotoAuth() -> Bool {
        var accessGranted = false
        PHPhotoLibrary.requestAuthorization { (status) -> Void in
            switch status {
            case .authorized:
                DDLogDebug("[SCPGalleryView] -> checkPhotoAuth() - user Authorized access to PhotoLibrary")
                accessGranted = true
            case .restricted, .denied:
                DDLogError("[SCPGalleryView] -> checkPhotoAuth() - user Denied access to PhotoLibrary")
            default:
                break
            }
        }
        return accessGranted
    }
}


