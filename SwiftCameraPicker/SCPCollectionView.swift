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

    fileprivate var collectionView: UICollectionView!
    fileprivate var cellReuseIdentifier = "SCPCollectionViewCell"
    var mediaSelectedLabelUpdateDelegate: SCPMediaSelectedLabelUpdateDelegate?
    var mediaFiles: [SCPAsset] = []
    var mediaSelectedLimit = 10 // default
    
    static func instance() -> SCPCollectionView {
        let bundle = Bundle(for: self.classForCoder())
        return UINib(nibName: "SCPCollectionView", bundle: bundle).instantiate(withOwner: self, options: nil)[0] as! SCPCollectionView
    }
    
    
    func initialize() {
//        self.mediaFiles = []
        if let collectionView = self.viewWithTag(100) as? UICollectionView {
            self.collectionView = collectionView
        }
        let bundle = Bundle(for: type(of: self))
        self.collectionView.register(UINib(nibName: "SCPCollectionViewCell", bundle: bundle), forCellWithReuseIdentifier: self.cellReuseIdentifier)
    }
    
    
    func addMediaFileToCollection(_ image: UIImage?, phAsset: PHAsset?, path: String? = nil, videoUrl: URL? = nil, avAsset: AVAsset? = nil, scpAsset: SCPAsset? = nil) {
        if self.getMediaSelectedCount() < self.mediaSelectedLimit {
            
            if scpAsset != nil {
                self.mediaFiles.insert(scpAsset!, at: 0)
                let indexPath = IndexPath(item: 0, section: 0)
                self.collectionView.insertItems(at: [indexPath])
                self.mediaSelectedLabelUpdateDelegate?.updateMediaSelectedLabel()
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
        if !self.mediaFiles.isEmpty {
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
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.mediaFiles.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SCPCollectionViewCell", for: indexPath) as! SCPCollectionViewCell

        cell.setup(self.mediaFiles[indexPath.row])
        return cell
        
    }
    
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    //
    // MARK: - UICollectionViewDelegate
    //
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let cell : SCPCollectionViewCell = collectionView.cellForItem(at: indexPath) as! SCPCollectionViewCell

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
