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
    private var mediaFile: SCPAsset!
    
    
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
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.setCellStateLayout(self.mediaFile.deleteToggle)
        })
    }
    
    
    func setCellStateLayout(selected: Bool) {
        if selected == true {
            self.visualEffect.hidden = false
            self.checkedState.hidden = true
            self.selected = true
            super.selected = true
        } else {
            self.visualEffect.hidden = true
            self.checkedState.hidden = false
            self.selected = false
            super.selected = false
        }
    }
    
    
    func setup(media: SCPAsset) {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.setCellStateLayout(media.deleteToggle)
            self.layer.cornerRadius = 8.0
            self.layer.borderWidth = 1
            self.layer.borderColor = UIColor.fromHex("#dddddd").CGColor
            self.mediaFile = media
            self.image = media.image
            if self.mediaFile.mediaType == SCPAsset.MediaTypes["video"] {
                self.videoFileIcon.hidden = false
            } else {
                self.videoFileIcon.hidden = true
            }
        })
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

}
