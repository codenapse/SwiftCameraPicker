//
//  SCPGalleryViewCell.swift
//  SwiftCameraPicker
//
//  Created by Alin Paulesc on 02/08/16.
//  Copyright © 2016 codenapse. All rights reserved.
//

import UIKit
import CocoaLumberjack


class SCPGalleryViewCell: UICollectionViewCell {
    
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var selectedFlagView: UIImageView!
    @IBOutlet var videoFileIcon: UIImageView!
    var mediaFile: SCPAsset!
    
    
    func toggle() {
//        DDLogDebug("toggle() - \(self.mediaFile.selected)")
        if self.mediaFile.selected == true {
            self.mediaFile.selected = false
        } else {
            self.mediaFile.selected = true
        }
        self.setCellStateLayout(self.mediaFile.selected)
    }
    
    func setup() {
        if self.mediaFile.mediaType == SCPAsset.MediaTypes["video"]! {
            self.videoFileIcon.isHidden = false
        } else {
            self.videoFileIcon.isHidden = true
        }
        self.setCellStateLayout(self.mediaFile.selected)
    }
    
    func setCellStateLayout(_ selected: Bool) {
        DispatchQueue.main.async(execute: { () -> Void in
            if selected == true {
                self.imageView.alpha = 0.5
                self.selectedFlagView.isHidden = false
            } else {
                self.imageView.alpha = 1.0
                self.selectedFlagView.isHidden = true
            }
            
        })
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        DispatchQueue.main.async(execute: { () -> Void in
            self.selectedFlagView.isHidden = true
        })
    }

}
