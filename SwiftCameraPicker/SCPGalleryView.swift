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
    var delegate: SCPCollectionDelegate!
//    var assets: [PHAsset] = []
    
    
    static func instance() -> SCPGalleryView {
        return UINib(nibName: "SCPGalleryView", bundle: NSBundle(forClass: self.classForCoder())).instantiateWithOwner(self, options: nil).first as! SCPGalleryView
    }
    
    func initialize() {
        let bundle = NSBundle(forClass: self.dynamicType)
        self.collectionView.registerNib(UINib(nibName: "SCPGalleryViewCell", bundle: bundle), forCellWithReuseIdentifier: self.cellReuseIdentifier)
        if self.mediaFiles.count == 0 {
            self.initMediaFiles()
        }
//        dispatch_async(dispatch_get_main_queue(), { () -> Void in
//            
//        })
    }
    func initMediaFiles() {
        self.checkPhotoAuth()
        DDLogDebug("[SCPGalleryView] -> initMediaFiles()")
        var assets: [PHAsset] = []
        let options = PHFetchOptions()
        options.sortDescriptors = [
            NSSortDescriptor(key: "creationDate", ascending: true)
        ]
        var results = PHAsset.fetchAssetsWithMediaType(.Image, options: options)
        results.enumerateObjectsUsingBlock { (object, _, _) in
            if let asset = object as? PHAsset {
                assets.append(asset)
                
            }
        }
        SCPMediaFile.imageManager.startCachingImagesForAssets(assets,
                                                              targetSize: CGSize(width: 110.0, height: 147.0),
                                                              contentMode: .AspectFill,
                                                              options: nil
        )
        for asset in assets {
            self.mediaFiles.append(SCPMediaFile(phAsset: asset, cellSize: CGSize(width: 110.0, height: 147.0)))
        }

        results = PHAsset.fetchAssetsWithMediaType(.Video, options: options)
        results.enumerateObjectsUsingBlock { (object, _, _) in
            if let asset = object as? PHAsset {
                DDLogDebug("\(asset.duration)")
                let mediaFile = SCPMediaFile(phAsset: asset, cellSize: CGSize(width: 110.0, height: 147.0))
                SCPMediaFile.imageManager.requestAVAssetForVideo(asset, options: nil, resultHandler: {(avAsset: AVAsset?, audioMix: AVAudioMix?, info: [NSObject : AnyObject]?) -> Void in
                    mediaFile.avAsset = avAsset!
                    mediaFile.mediaType = SCPMediaFile.MediaTypes["video"]!
                    self.mediaFiles.append(mediaFile)
                })
                
            }
        }
    }
    //
    // MARK: - UICollectionViewDataSource
    //
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        DDLogDebug("Media files count = \(self.mediaFiles.count)")
        return self.mediaFiles.count
    }
    //
    //
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("SCPGalleryViewCell", forIndexPath: indexPath) as! SCPGalleryViewCell
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            let mediaFile = self.mediaFiles[indexPath.row]
            cell.imageView?.image = mediaFile.image
            cell.mediaFile = mediaFile
            cell.setup()
//        })
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
        DDLogDebug("[SCPGalleryView] -> collectionView() -> media file tapped")
        let cell : SCPGalleryViewCell = collectionView.cellForItemAtIndexPath(indexPath) as! SCPGalleryViewCell
        if self.delegate.mediaSelectedLimitReached() == true {
            return
        }
        let asset = self.mediaFiles[indexPath.row]
        if asset.selected == true {
            return
        }
        if cell.mediaFile.mediaType == SCPMediaFile.MediaTypes["video"] {
            let path = self.delegate.getVideoFilePath()
            let exportUrl: NSURL = NSURL.fileURLWithPath(path)
            var exporter = AVAssetExportSession(asset: cell.mediaFile.avAsset!, presetName: AVAssetExportPresetHighestQuality)
            exporter?.outputURL = exportUrl
            exporter?.outputFileType = AVFileTypeMPEG4
            exporter?.exportAsynchronouslyWithCompletionHandler({
                var thumb = cell.mediaFile.getThumbnailFromVideo()
                var thumbPath = path.stringByReplacingOccurrencesOfString(".mp4", withString: ".jpg")
                var imgData: NSData = UIImageJPEGRepresentation(thumb!, 0.85)!
                imgData.writeToFile(thumbPath, atomically: true)
                DDLogDebug("[SCPGalleryView] -> collectionView() -> video thumb: \(thumbPath)")
            })
            self.delegate.mediaFileRecorded(exportUrl, avAsset: cell.mediaFile.avAsset!)
        } else {
            self.delegate.mediaFileSelected(cell.imageView.image!, phAsset: asset.phAsset)
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


