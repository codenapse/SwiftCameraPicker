//
//  SCPGalleryViewCell.swift
//  SwiftCameraPicker
//
//  Created by Alin Paulesc on 02/08/16.
//  Copyright © 2016 codenapse. All rights reserved.
//

import UIKit

class SCPGalleryViewCell: UICollectionViewCell {
    
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var selectedFlagView: UIImageView!
    @IBOutlet var videoFileIcon: UIImageView!
    var mediaFile: SCPMediaFile!
    
    
    func toggle() {
      
        if self.mediaFile.selected == true {
            self.mediaFile.selected = false
        } else {
            self.mediaFile.selected = true
        }
        self.setCellStateLayout(self.mediaFile.selected)
    }
    
    func setup() {
        if self.mediaFile.mediaType == SCPMediaFile.MediaTypes["video"]! {
            self.videoFileIcon.hidden = false
        } else {
            self.videoFileIcon.hidden = true
        }
        self.setCellStateLayout(self.mediaFile.selected)
    }
    
    func setCellStateLayout(selected: Bool) {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            if selected == true {
                self.imageView.alpha = 0.5
                self.selectedFlagView.hidden = false
            } else {
                self.imageView.alpha = 1.0
                self.selectedFlagView.hidden = true
            }
            
        })
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.selectedFlagView.hidden = true
        })
    }

}
