//
//  SCPCollectionViewCell.swift
//  SwiftCameraPicker
//
//  Created by Alin Paulesc on 26/07/16.
//  Copyright © 2016 codenapse. All rights reserved.
//

import UIKit
import Photos

class SCPCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet var visualEffect: UIVisualEffectView!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var videoFileIcon: UIImageView!
    @IBOutlet var checkedState: UIImageView!
    fileprivate var mediaFile: SCPAsset!
    
    
    var image: UIImage! {
        didSet {
            imageView.image = image
        }
    }
    
    
    func toggle() {
        if self.mediaFile.deleteToggle == true {
            self.mediaFile.deleteToggle = false
        } else {
            self.mediaFile.deleteToggle = true
        }
        DispatchQueue.main.async(execute: { () -> Void in
            self.setCellStateLayout(self.mediaFile.deleteToggle)
        })
    }
    
    
    func setCellStateLayout(_ selected: Bool) {
        if selected == true {
            self.visualEffect.isHidden = false
            self.checkedState.isHidden = true
            self.isSelected = true
            super.isSelected = true
        } else {
            self.visualEffect.isHidden = true
            self.checkedState.isHidden = false
            self.isSelected = false
            super.isSelected = false
        }
    }
    
    
    func setup(_ media: SCPAsset) {
        DispatchQueue.main.async(execute: { () -> Void in
            self.setCellStateLayout(media.deleteToggle)
            self.layer.cornerRadius = 8.0
            self.layer.borderWidth = 1
            self.layer.borderColor = UIColor.fromHex("#dddddd").cgColor
            self.mediaFile = media
            self.image = media.image
            if self.mediaFile.mediaType == SCPAsset.MediaTypes["video"] {
                self.videoFileIcon.isHidden = false
            } else {
                self.videoFileIcon.isHidden = true
            }
        })
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

}
