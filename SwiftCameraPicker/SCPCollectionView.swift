//
//  SCPCollectionView.swift
//  SwiftCameraPicker
//
//  Created by Alin Paulesc on 25/07/16.
//  Copyright © 2016 codenapse. All rights reserved.
//

import UIKit
import CocoaLumberjack
import Photos


class SCPCollectionView: UIView, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    private var collectionView: UICollectionView!
    private var cellReuseIdentifier = "SCPCollectionViewCell"
    var mediaSelectedLabelUpdateDelegate: SCPMediaSelectedLabelUpdateDelegate?
    var mediaFiles: [SCPMediaFile?]!
    var mediaSelectedLimit = 10 // default
    
    static func instance() -> SCPCollectionView {
        let bundle = NSBundle(forClass: self.classForCoder())
        return UINib(nibName: "SCPCollectionView", bundle: bundle).instantiateWithOwner(self, options: nil)[0] as! SCPCollectionView
    }
    
    
    func initialize() {
        self.mediaFiles = nil
        if let collectionView = self.viewWithTag(100) as? UICollectionView {
            self.collectionView = collectionView
        }
        let bundle = NSBundle(forClass: self.dynamicType)
        self.collectionView.registerNib(UINib(nibName: "SCPCollectionViewCell", bundle: bundle), forCellWithReuseIdentifier: self.cellReuseIdentifier)
    }
    
    
    func addMediaFileToCollection(image: UIImage?, phAsset: PHAsset?, path: String? = nil, videoUrl: NSURL? = nil, avAsset: AVAsset? = nil) {
        if self.getMediaSelectedCount() < self.mediaSelectedLimit {
            var media: SCPMediaFile?
            if path != nil {
                media = SCPMediaFile(mediaPath: path!)
            } else if phAsset != nil {
                media = SCPMediaFile(phAsset: phAsset!)
            } else if avAsset != nil {
                media = SCPMediaFile(avAsset: avAsset!)
                media!.mediaPath = videoUrl!.absoluteString
                media!.mediaType = SCPMediaFile.MediaTypes["video"]!
                do {
                    let bigThumbPath = videoUrl!.path!.stringByReplacingOccurrencesOfString("_original.mp4", withString: "_preview.jpg")
                    let img = media!.getThumbnailFromVideo(800)
                    let imgData: NSData = UIImageJPEGRepresentation(img!, 0.85)!
                    _ = try Bool(imgData.writeToFile(bigThumbPath, options: NSDataWritingOptions.DataWritingAtomic))
                } catch let err as NSError {
                    DDLogDebug(err.description)
                }
            } else {
                let asset: AVAsset
                if videoUrl != nil {
                    asset = AVAsset(URL: videoUrl!)
                    media = SCPMediaFile(avAsset: asset)
                    media!.mediaPath = videoUrl!.absoluteString
                    media!.mediaType = SCPMediaFile.MediaTypes["video"]!
                    do {
                        let thumbPath = videoUrl!.path!.stringByReplacingOccurrencesOfString("_original.mp4", withString: "_thumb.jpg")
                        let img = media!.getThumbnailFromVideo()
                        let imgData: NSData = UIImageJPEGRepresentation(img!, 0.85)!
                        _ = try Bool(imgData.writeToFile(thumbPath, options: NSDataWritingOptions.DataWritingAtomic))
                    } catch let err as NSError {
                        DDLogDebug(err.description)
                    }
                    do {
                        let bigThumbPath = videoUrl!.path!.stringByReplacingOccurrencesOfString("_original.mp4", withString: "_preview.jpg")
                        let img = media!.getThumbnailFromVideo(800)
                        let imgData: NSData = UIImageJPEGRepresentation(img!, 0.85)!
                        _ = try Bool(imgData.writeToFile(bigThumbPath, options: NSDataWritingOptions.DataWritingAtomic))
                    } catch let err as NSError {
                        DDLogDebug(err.description)
                    }
                }
            }
            
            let index = 0
            if self.mediaFiles == nil {
                self.mediaFiles = []
            }
            if media != nil {
                self.mediaFiles.insert(media, atIndex: index)
                let indexPath = NSIndexPath(forItem: index, inSection: 0)
                self.collectionView.insertItemsAtIndexPaths([indexPath])
            }
            return
        }
        DDLogDebug("[SCPCollectionView] -> addMediaFileToCollection() -> selected media files limit reached: \(self.mediaSelectedLimit)")
        
    }
    
    
    func getMediaFilesFromSession() -> [SCPMediaFile?] {
        if self.mediaFiles != nil {
            return self.mediaFiles
        }
        return []
    }
    
    
    func getMediaSelectedCount() -> Int {
        var counter = 0
        if self.mediaFiles != nil {
            for item in self.mediaFiles {
                if item!.deleteToggle == false {
                    counter += 1
                }
            }
        }
        return counter
    }
    //
    // MARK: - UICollectionViewDataSource
    //
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if self.mediaFiles != nil {
            return self.mediaFiles.count
        }
        return 0
    }
    
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("SCPCollectionViewCell", forIndexPath: indexPath) as! SCPCollectionViewCell

        cell.setup(self.mediaFiles[indexPath.row]!)
        return cell
        
    }
    
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    //
    // MARK: - UICollectionViewDelegate
    //
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let cell : SCPCollectionViewCell = collectionView.cellForItemAtIndexPath(indexPath) as! SCPCollectionViewCell

        if self.getMediaSelectedCount() < self.mediaSelectedLimit {
            cell.toggle()
        } else if self.mediaFiles[indexPath.row]!.deleteToggle == false {
            cell.toggle()
        }
        self.mediaSelectedLabelUpdateDelegate!.updateMediaSelectedLabel()
    }
}

protocol SCPMediaSelectedLabelUpdateDelegate {
    func updateMediaSelectedLabel()
}
