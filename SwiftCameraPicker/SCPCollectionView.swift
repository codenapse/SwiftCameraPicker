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
    var mediaFiles: [SCPAsset] = []
    var mediaSelectedLimit = 10 // default
    
    static func instance() -> SCPCollectionView {
        let bundle = NSBundle(forClass: self.classForCoder())
        return UINib(nibName: "SCPCollectionView", bundle: bundle).instantiateWithOwner(self, options: nil)[0] as! SCPCollectionView
    }
    
    
    func initialize() {
//        self.mediaFiles = []
        if let collectionView = self.viewWithTag(100) as? UICollectionView {
            self.collectionView = collectionView
        }
        let bundle = NSBundle(forClass: self.dynamicType)
        self.collectionView.registerNib(UINib(nibName: "SCPCollectionViewCell", bundle: bundle), forCellWithReuseIdentifier: self.cellReuseIdentifier)
    }
    
    
    func addMediaFileToCollection(image: UIImage?, phAsset: PHAsset?, path: String? = nil, videoUrl: NSURL? = nil, avAsset: AVAsset? = nil, scpAsset: SCPAsset? = nil) {
        if self.getMediaSelectedCount() < self.mediaSelectedLimit {
            
            if scpAsset != nil {
                self.mediaFiles.insert(scpAsset!, atIndex: 0)
                let indexPath = NSIndexPath(forItem: 0, inSection: 0)
                self.collectionView.insertItemsAtIndexPaths([indexPath])
            }
            return
        }
        DDLogDebug("[SCPCollectionView] -> addMediaFileToCollection() -> selected media files limit reached: \(self.mediaSelectedLimit)")
        
    }
    
    
    func getMediaFilesFromSession() -> [SCPAsset] {
        if self.mediaFiles.count > 0 {
            return self.mediaFiles
        }
        return []
    }
    
    
    func getMediaSelectedCount() -> Int {
        var counter = 0
        if self.mediaFiles.isEmpty {
            for item in self.mediaFiles {
                if item.deleteToggle == false {
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
        return self.mediaFiles.count
    }
    
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("SCPCollectionViewCell", forIndexPath: indexPath) as! SCPCollectionViewCell

        cell.setup(self.mediaFiles[indexPath.row])
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
        } else if self.mediaFiles[indexPath.row].deleteToggle == false {
            cell.toggle()
        }
        self.mediaSelectedLabelUpdateDelegate!.updateMediaSelectedLabel()
    }
}

protocol SCPMediaSelectedLabelUpdateDelegate {
    func updateMediaSelectedLabel()
}
