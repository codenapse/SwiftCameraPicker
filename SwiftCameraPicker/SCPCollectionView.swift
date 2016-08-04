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
    var mediaSelectedLimit = 15 // default
    
    static func instance() -> SCPCollectionView {
        return UINib(nibName: "SCPCollectionView", bundle: NSBundle(forClass: self.classForCoder())).instantiateWithOwner(self, options: nil)[0] as! SCPCollectionView
    }
    //
    //
    //
    func initialize() {
        self.mediaFiles = nil
        if let collectionView = self.viewWithTag(100) as? UICollectionView {
            self.collectionView = collectionView
        }
        self.collectionView.registerNib(UINib(nibName: "SCPCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: self.cellReuseIdentifier)
        self.initMediaFiles()
//        self.layoutIfNeeded()
    }
    //
    //
    //
    func initMediaFiles() {
        // MARK:- Mook initMediaFiles()
//        self.mediaFiles.append(SCPMediaFile(image: SCPMediaFile.imageWithColor(UIColor.cyanColor())))
//        self.mediaFiles.append(SCPMediaFile(image: SCPMediaFile.imageWithColor(UIColor.blueColor())))
    }
    //
    //
    //
    func addMediaFileToCollection(image: UIImage, phAsset: PHAsset! = nil) {
        if self.getMediaSelectedCount() < self.mediaSelectedLimit {
            let media = SCPMediaFile(image: image, phAsset: phAsset)
            let index = 0 //count > 0 ? count - 1 : count
            if self.mediaFiles == nil {
                self.mediaFiles = []
            }
            self.mediaFiles.insert(media, atIndex: index)
            let indexPath = NSIndexPath(forItem: index, inSection: 0)
            self.collectionView.insertItemsAtIndexPaths([indexPath])
            return
        }
        DDLogDebug("[SCPCollectionView] -> addMediaFileToCollection() -> selected media files limit reached: \(self.mediaSelectedLimit)")
        
    }
    //
    //
    //
    func getMediaFilesFromSession() -> [SCPMediaFile?] {
        if self.mediaFiles != nil {
            return self.mediaFiles
        }
        return []
    }
    //
    //
    //
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
    //
    //
    //
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("SCPCollectionViewCell", forIndexPath: indexPath) as! SCPCollectionViewCell

        cell.setup(self.mediaFiles[indexPath.row]!)
        return cell
        
    }
    //
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
        
        let cell : SCPCollectionViewCell = collectionView.cellForItemAtIndexPath(indexPath) as! SCPCollectionViewCell

        if self.getMediaSelectedCount() < self.mediaSelectedLimit {
            cell.toggle()
        } else if self.mediaFiles[indexPath.row]!.deleteToggle == false {
            cell.toggle()
        }
        self.mediaSelectedLabelUpdateDelegate!.updateMediaSelectedLabel()
    }
    //
    // MARK: -
    // MARK: - UICollectionViewFlowLayout
    //
//    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
//        let picDimension = self.frame.size.width / 4.0
//        return CGSizeMake(picDimension, picDimension)
//    }
//    
//    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
//        let leftRightInset = self.frame.size.width / 14.0
//        return UIEdgeInsetsMake(0, leftRightInset, 0, leftRightInset)
//    }
}

protocol SCPMediaSelectedLabelUpdateDelegate {
    func updateMediaSelectedLabel()
}
